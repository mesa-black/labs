---
title: "Notre couche Domaine ne contient que des exceptions. C'est délibéré."
standfirst: "Neuf contextes, vingt-neuf commandes, un seul gestionnaire de requête, aucun port. Ce qu'on a gardé de DDD et de l'architecture hexagonale, ce qu'on a refusé, et les cinq endroits où l'infrastructure traverse la frontière quand même. Ce n'est pas du DDD puriste, c'est du time to market."
key: domaine-sans-ports
date: 2026-10-04
slug: notre-domaine-ne-contient-que-des-exceptions
---

Les articles sur l'architecture hexagonale montrent presque toujours le même schéma : un cercle au milieu, des ports tout autour, des adaptateurs à l'extérieur, et une flèche qui rentre. Aucun ne montre ce que contient le dossier `Domain/` six mois après.

Voici le nôtre. Neuf contextes, et au total douze fichiers de domaine : neuf exceptions, deux énumérations, un rôle. Zéro interface. Zéro agrégat. Zéro objet-valeur. Appeler ça une couche métier serait un mensonge, et c'est précisément le sujet de cet article.

## Ce qu'on a gardé : le C de CQRS, pas le Q

La configuration du bus déclare trois canaux, avec une sémantique explicite :

```yaml
default_bus: command.bus
buses:
    command.bus:            # une commande mute l'état, exactement un gestionnaire
        default_middleware: { enabled: true, allow_no_handlers: false }
    query.bus:              # une requête renvoie une valeur, un seul gestionnaire
        default_middleware: { enabled: true, allow_no_handlers: false }
    event.bus:              # un événement de domaine : 0..n abonnés
        default_middleware: { enabled: true, allow_no_handlers: true }
```

Le décompte réel, aujourd'hui : **vingt-neuf gestionnaires de commande, un seul gestionnaire de requête.** Le bus de requêtes existe, il est configuré, il est presque vide.

Ce n'est pas un retard de migration, c'est une conclusion. Une commande vaut sa cérémonie parce qu'elle apporte trois choses qu'on n'avait pas : un nom d'intention (`ChangeCompanySubscriptionPlan` n'est pas `setSubscriptionPlan`), la garantie qu'il existe exactement un endroit qui l'exécute — `allow_no_handlers: false` échoue au démarrage, pas en production — et une frontière de transaction évidente, celle du gestionnaire.

Une lecture n'apporte rien de tout ça. Sa forme est dictée par l'écran qui l'affiche : cette page a besoin de ces sept colonnes, jointes de cette façon, triées comme ça. Faire passer ça par un bus n'ajoute aucune règle, ajoute une couche, et déplace le SQL d'un fichier à un autre. On lit donc par les dépôts Doctrine, directement, sans s'en excuser.

Détail qui compte plus qu'il n'en a l'air : `default_bus: command.bus`. Un `dispatch()` nu est une commande. La valeur par défaut est celle qui mute l'état, donc la seule qu'on ne veut jamais voir partir par accident sur le mauvais canal.

## Ce qu'on a refusé : l'inversion de dépendance

C'est le cœur de l'hexagone dans la littérature : le domaine définit des interfaces, l'infrastructure les implémente, la flèche de dépendance pointe vers l'intérieur. On ne l'a pas fait. Voici un gestionnaire entier, sans coupe :

```php
#[AsMessageHandler(bus: 'command.bus')]
final readonly class ChangeCompanySubscriptionPlanHandler
{
    public function __construct(
        private EntityManagerInterface $entityManager,
        private LoggerInterface $logger,
    ) {}

    public function __invoke(ChangeCompanySubscriptionPlanCommand $command): void
    {
        $company = $this->entityManager->find(Company::class, Ulid::fromString($command->companyId));
        if (!$company instanceof Company) {
            throw CompanyNotFoundException::withId($command->companyId);
        }
        // …
    }
}
```

`EntityManagerInterface` en dépendance directe. Sur trente-huit gestionnaires, **vingt-quatre** en dépendent. L'entité `Company` vient de `App\Entity`, partagée par tous les contextes. Il n'y a pas de dépôt abstrait, pas de port, pas de modèle de domaine distinct de la table.

Deux remarques sur cet exemple, parce qu'elles disent plus que le schéma.

D'abord, la commande transporte `string $companyId`, pas un objet-valeur `CompanyId`. Ce n'est pas de la paresse : le message doit pouvoir être sérialisé pour le transport asynchrone. La frontière du bus impose la forme du message — de l'infrastructure qui dicte la signature de ce qu'on appelle le domaine, dès la première ligne.

Ensuite, `Ulid::fromString(...)`. L'identifiant du domaine existe en deux formes selon qu'on le transporte ou qu'on l'interroge, et la conversion est une contrainte du stockage, pas du métier.

## Ce que la frontière achète quand même

Une chose, une seule, et elle vaut son prix : **le couplage entre contextes est devenu visible dans la liste des imports.**

Le gestionnaire ci-dessus vit dans `App\Billing`. Il importe `App\Company\Domain\Exception\CompanyNotFoundException`. Ce seul import dit que la facturation dépend du contexte Entreprise, et il le dit en haut du fichier, en une ligne, sans diagramme à tenir à jour. Le graphe de dépendances entre contextes s'obtient avec un `grep` sur les `use`.

C'est modeste. Comparé à une base où tout vit dans `App\Service`, c'est la différence entre « on suppose que c'est couplé » et « voilà exactement où ». C'est ce bénéfice-là qu'on a acheté, et rien d'autre.

## Les cinq endroits où l'infrastructure traverse

Voilà ce qu'aucun schéma ne montre : les endroits où Doctrine décide de la forme d'une opération métier. Ce sont des fuites réelles, toutes présentes dans le code aujourd'hui.

**1. La règle métier écrite en deux dialectes.** Notre politique d'exclusion des entreprises internes des chiffres commerciaux tient en un prédicat. Elle existe en deux versions, parce que certains chemins de lecture sont en SQL natif pour la performance et d'autres en DQL :

```php
public static function sql(string $alias = 'c'): string  // requêtes natives
{ return ($alias !== '' ? $alias.'.' : '').'excluded_from_stats = false'; }

public static function dql(string $alias = 'c'): string  // requêtes de l'ORM
{ return $alias.'.excludedFromStats = false'; }
```

Une règle, deux écritures, à cause du langage de requête. La divergence est d'un caractère — `excluded_from_stats` contre `excludedFromStats` — donc invisible à la relecture rapide, et il n'existe aucun test qui échouerait si l'une des deux partait à la dérive.

**2. Le filtre ambiant.** Le filtre de suppression logique de Doctrine est un état global mutable. Une requête qui cherche un identifiant unique ne trouve rien alors que l'index unique, lui, le retient toujours. On s'en sort en désactivant le filtre, puis en le remettant :

```php
$filters = $this->em->getFilters();
$wasEnabled = $filters->isEnabled('softdeleteable');
if ($wasEnabled) { $filters->disable('softdeleteable'); }
$existing = $repo->findOneBy(['slug' => $slug]);
if ($wasEnabled) { $filters->enable('softdeleteable'); }
```

Une « requête métier » dont le résultat dépend d'un état ambiant n'est pas une fonction. Ce n'est pas un défaut de Doctrine — le filtre est exactement ce qu'on lui demande — mais ça interdit de raisonner sur le code applicatif sans savoir dans quel mode il s'exécute.

**3. L'ordre des écritures dans l'unité de travail.** Remplacer les traductions d'un contenu semble être une opération : on retire les anciennes, on ajoute les nouvelles, on enregistre. Dans un seul `flush()`, Doctrine exécute les `INSERT` avant les `DELETE` d'orphelins, et la contrainte d'unicité sur `(feedback_id, locale)` casse. L'opération doit être coupée en deux enregistrements successifs.

Autrement dit : la découpe de l'opération applicative n'est pas dictée par le métier mais par l'ordonnancement interne de l'ORM. Aucun port n'aurait protégé de ça, parce que la contrainte ne vit ni dans le domaine ni dans l'adaptateur — elle vit dans le calendrier d'exécution qui les relie.

**4. L'alias de jointure qui tronque en silence.** Filtrer sur une association déjà jointe en `fetch` restreint aussi la collection hydratée : on croit filtrer les lignes, on ampute l'objet retourné. Il faut une seconde jointure dédiée au filtrage :

```php
$qb->innerJoin('f.industries', 'i_filter')      // alias distinct de celui du fetch
   ->andWhere('i_filter.id IN (:industries)');
```

Le bug ne se voit pas : la requête renvoie les bonnes entités, avec des collections incomplètes. C'est de la sémantique d'infrastructure, au beau milieu de ce qui ressemble à une règle de recherche.

**5. Le type de l'identifiant.** Les identifiants circulent en ULID, se comparent en RFC 4122 dans les requêtes, et l'oubli de la conversion produit un résultat vide plutôt qu'une erreur. Un port aurait déplacé la conversion ; il ne l'aurait pas supprimée.

## La règle de migration

Reste la question qui tue les refontes : que fait-on du code existant, écrit en services Symfony classiques ?

Rien, tant que personne ne le touche. La politique est écrite : **CQRS pour les nouvelles écritures et les nouvelles lectures ; migration de l'existant à la demande uniquement.** Jamais de réécriture en masse au nom de l'homogénéité.

Parce que l'homogénéité n'est pas un résultat métier. Réécrire un service qui fonctionne pour qu'il ressemble à ses voisins, c'est produire du risque sans produire de valeur — et c'est exactement le genre de travail qui se justifie tout seul, indéfiniment, parce que son critère d'arrêt est esthétique.

## Ce n'est pas du DDD puriste, c'est du time to market

Il faut nommer la vraie raison, parce que tout ce qui précède se lit autrement une fois qu'elle est posée.

On a déjà écrit ici que [la fonctionnalité la moins chère est celle qu'on ne construit pas](/le-code-qu-on-n-ecrit-pas/). Un port est une fonctionnalité. Un agrégat aussi, un objet-valeur aussi, une couche anticorruption aussi. Chacun a un coût d'écriture, un coût de lecture pour celui qui arrivera après, et un coût d'entretien qui court aussi longtemps que le code vit. Une abstraction n'est pas gratuite parce qu'elle est immatérielle.

La question utile n'est donc pas « est-ce du DDD correct ». C'est : qu'est-ce que cette abstraction achète aujourd'hui, et qu'est-ce qu'elle se contente de repousser ? Un dépôt derrière une interface achète la possibilité de changer de stockage — nous ne quitterons pas PostgreSQL. Il achète aussi des tests sans base de données, et ça, c'est un vrai bénéfice : c'est le seul argument qui nous fera peut-être payer la facture un jour.

Ce qu'on a fait à la place tient en une phrase : livrer, et ne garder que les frontières qui se paient toutes seules. Le bus de commandes coûte trois fichiers et rend service le jour même. Les ports coûtent une couche entière et rendront peut-être service, plus tard, à une équipe qui n'existe pas encore.

Le risque de cette position est connu, et l'écrire fait partie du prix : elle ressemble à s'y méprendre à de la paresse. La différence tient à un seul détail — on sait nommer ce qu'on n'a pas construit, et pourquoi.

Et on assume. Ces choix sont les nôtres, pas des accidents qu'on découvrirait en relisant. On les corrige quand on peut et quand on a le temps : le jour où une gêne devient réelle et mesurable, pas le jour où un article d'architecture nous explique qu'ils sont incorrects. Une dette écrite, datée et argumentée n'est pas une dette niée — c'est la seule qu'on soit capable de rembourser au bon moment.

## Ce que ça a donné

- **Neuf contextes nommés**, dont le couplage mutuel se lit dans les imports plutôt que dans un diagramme périmé.
- **Vingt-neuf commandes**, chacune avec un nom d'intention, un gestionnaire unique garanti au démarrage et une frontière de transaction évidente.
- **Un seul gestionnaire de requête**, assumé : les lectures passent par les dépôts.
- **Douze fichiers de domaine** — neuf exceptions, deux énumérations, un rôle — c'est-à-dire aucune règle métier réellement isolée de Doctrine.
- **Zéro réécriture** du code classique existant, qui continue de fonctionner à côté.

## Bonnes pratiques

- Traiter chaque abstraction comme une fonctionnalité : elle doit dire ce qu'elle achète aujourd'hui, pas ce qu'elle permettrait un jour.
- Adopter les morceaux séparément. Le bus de commandes apporte quelque chose sans le reste ; les ports, les agrégats et les objets-valeurs sont des achats distincts, avec chacun leur facture.
- Choisir la valeur par défaut la plus contraignante : le bus par défaut est celui qui mute l'état, et l'absence de gestionnaire fait échouer le démarrage plutôt que la production.
- Se servir des espaces de noms comme d'un révélateur de couplage plutôt que comme d'une barrière : ils ne protègent de rien, ils rendent visible.
- Écrire la règle de migration, avec son critère d'arrêt. Sans critère d'arrêt, « harmoniser l'architecture » est un travail infini.
- Regarder ce que contient réellement `Domain/` avant de dire qu'on fait du DDD. Le décompte est instructif.

## Points de vigilance

- **Le dossier n'est pas la frontière.** Créer `Domain/`, `Application/`, `Infrastructure/` donne une impression d'avancement mesurable — et mesurer une architecture au nombre de dossiers est la meilleure façon de n'obtenir aucune des garanties qu'ils suggèrent.
- **Vingt-quatre gestionnaires sur trente-huit dépendent de l'`EntityManager`** : aucun ne peut être testé avec un dépôt en mémoire. La suite de tests a besoin d'une vraie base. C'est un coût, il est assumé, il n'est pas gratuit.
- **Les entités Doctrine partagées sont le vrai couplage**, et il est invisible dans l'arborescence. Le jour où deux contextes voudront faire diverger la même table, c'est ce mur-là qu'on rencontrera, pas l'absence de ports.
- **Une règle métier dupliquée dans deux dialectes de requête finira par diverger**, et aujourd'hui rien ne le détecterait. C'est la dette la plus concrète de tout ce qui précède.
