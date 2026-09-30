---
title: "Nuestra capa de dominio solo contiene excepciones. A propósito."
standfirst: "Nueve contextos, veintinueve comandos, un único manejador de consultas, cero puertos. Qué conservamos de DDD y de la arquitectura hexagonal, qué rechazamos, y los cinco puntos por donde la infraestructura cruza igualmente la frontera."
key: domaine-sans-ports
date: 2026-10-04
slug: nuestro-dominio-solo-contiene-excepciones
---

Los artículos sobre arquitectura hexagonal muestran casi siempre el mismo esquema: un círculo en el centro, puertos alrededor, adaptadores fuera y una flecha que apunta hacia dentro. Ninguno enseña nunca qué contiene la carpeta `Domain/` seis meses después.

Aquí está la nuestra. Nueve contextos y, en total, doce archivos de dominio: nueve excepciones, dos enumeraciones, un rol. Cero interfaces. Cero agregados. Cero objetos de valor. Llamar a eso capa de negocio sería mentir, y de eso trata exactamente este artículo.

## Lo que conservamos: la C de CQRS, no la Q

La configuración del bus declara tres canales con una semántica explícita:

```yaml
default_bus: command.bus
buses:
    command.bus:            # un comando muta el estado, exactamente un manejador
        default_middleware: { enabled: true, allow_no_handlers: false }
    query.bus:              # una consulta devuelve un valor, un único manejador
        default_middleware: { enabled: true, allow_no_handlers: false }
    event.bus:              # un evento de dominio: 0..n suscriptores
        default_middleware: { enabled: true, allow_no_handlers: true }
```

El recuento real a día de hoy: **veintinueve manejadores de comando, uno solo de consulta.** El bus de consultas existe, está configurado y está casi vacío.

No es deuda de migración, es una conclusión. Un comando merece su ceremonia porque aporta tres cosas que antes no teníamos: un nombre de intención (`ChangeCompanySubscriptionPlan` no es `setSubscriptionPlan`), la garantía de que existe exactamente un sitio que lo ejecuta — `allow_no_handlers: false` falla al arrancar, no en producción — y una frontera de transacción evidente, la del manejador.

Una lectura no aporta nada de eso. Su forma la dicta la pantalla que la muestra: esta página necesita estas siete columnas, unidas así, ordenadas de esta manera. Pasar eso por un bus no añade ninguna regla, añade una capa y traslada el SQL de un archivo a otro. Así que leemos a través de los repositorios de Doctrine, directamente, y sin pedir perdón por ello.

Un detalle que importa más de lo que parece: `default_bus: command.bus`. Un `dispatch()` sin más es un comando. El valor por defecto es el canal que muta el estado, es decir, el único que nunca quieres ver saliendo por el canal equivocado.

## Lo que rechazamos: la inversión de dependencias

Es el corazón del hexágono en la literatura: el dominio declara interfaces, la infraestructura las implementa, la flecha de dependencia apunta hacia dentro. No lo hicimos. Aquí va un manejador entero, sin cortes:

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

`EntityManagerInterface` como dependencia directa. De treinta y ocho manejadores, **veinticuatro** dependen de él. La entidad `Company` viene de `App\Entity`, compartida por todos los contextos. No hay repositorio abstracto, ni puerto, ni modelo de dominio distinto de la tabla.

Dos observaciones sobre ese ejemplo, porque dicen más que el esquema.

Primera: el comando transporta `string $companyId`, no un objeto de valor `CompanyId`. No es pereza: el mensaje tiene que poder serializarse para el transporte asíncrono. La frontera del bus impone la forma del mensaje — infraestructura dictando la firma de lo que llamamos dominio, desde la primera línea.

Segunda: `Ulid::fromString(...)`. El identificador del dominio existe en dos formas según se transporte o se consulte con él, y esa conversión es una restricción del almacenamiento, no del negocio.

## Lo que la frontera compra de todos modos

Una cosa, exactamente una, y vale su precio: **el acoplamiento entre contextos se volvió visible en la lista de importaciones.**

El manejador anterior vive en `App\Billing`. Importa `App\Company\Domain\Exception\CompanyNotFoundException`. Esa sola importación dice que la facturación depende del contexto Empresa, y lo dice en la cabecera del archivo, en una línea, sin ningún diagrama que mantener al día. El grafo de dependencias entre contextos se obtiene con un `grep` sobre los `use`.

Es modesto. Comparado con una base donde todo vive en `App\Service`, es la diferencia entre «suponemos que está acoplado» y «aquí está exactamente dónde». Ese beneficio es lo que compramos, y nada más.

## Los cinco puntos por donde cruza la infraestructura

Esto es lo que ningún esquema enseña: los sitios donde Doctrine decide la forma de una operación de negocio. Son fugas reales, todas presentes hoy en el código.

**1. La regla de negocio escrita en dos dialectos.** Nuestra política para mantener a las empresas internas fuera de las cifras comerciales cabe en un predicado. Existe en dos versiones, porque algunos caminos de lectura son SQL nativo por rendimiento y otros son DQL:

```php
public static function sql(string $alias = 'c'): string  // consultas nativas
{ return ($alias !== '' ? $alias.'.' : '').'excluded_from_stats = false'; }

public static function dql(string $alias = 'c'): string  // consultas del ORM
{ return $alias.'.excludedFromStats = false'; }
```

Una regla, dos escrituras, por culpa del lenguaje de consulta. La divergencia es de un carácter — `excluded_from_stats` frente a `excludedFromStats` — así que resulta invisible en una lectura rápida, y no hay ninguna prueba que fallara si una de las dos se desviara.

**2. El filtro ambiental.** El filtro de borrado lógico de Doctrine es estado global mutable. Una consulta que busca un identificador único no encuentra nada mientras el índice único sí lo sigue reteniendo. La salida es desactivar el filtro y volver a ponerlo:

```php
$filters = $this->em->getFilters();
$wasEnabled = $filters->isEnabled('softdeleteable');
if ($wasEnabled) { $filters->disable('softdeleteable'); }
$existing = $repo->findOneBy(['slug' => $slug]);
if ($wasEnabled) { $filters->enable('softdeleteable'); }
```

Una «consulta de negocio» cuyo resultado depende de un estado ambiental no es una función. No es un defecto de Doctrine — el filtro hace exactamente lo que le pedimos — pero impide razonar sobre el código de aplicación sin saber en qué modo se ejecuta.

**3. El orden de escritura dentro de la unidad de trabajo.** Reemplazar las traducciones de un contenido parece una sola operación: quitar las antiguas, añadir las nuevas, guardar. Dentro de un único `flush()`, Doctrine ejecuta los `INSERT` antes que los `DELETE` de huérfanos, y la restricción de unicidad sobre `(feedback_id, locale)` revienta. Hay que partir la operación en dos guardados sucesivos.

Dicho de otro modo: la forma de la operación aplicativa no la fija el negocio, sino la planificación interna del ORM. Ningún puerto habría protegido de eso, porque la restricción no vive ni en el dominio ni en el adaptador: vive en el orden de ejecución que los une.

**4. El alias de unión que trunca en silencio.** Filtrar sobre una asociación ya unida con `fetch` restringe además la colección hidratada: crees que filtras filas y estás amputando el objeto devuelto. El filtrado necesita su propia segunda unión:

```php
$qb->innerJoin('f.industries', 'i_filter')      // alias distinto del de fetch
   ->andWhere('i_filter.id IN (:industries)');
```

El fallo es invisible: la consulta devuelve las entidades correctas, con colecciones incompletas. Es semántica de infraestructura, en mitad de lo que parece una regla de búsqueda.

**5. El tipo del identificador.** Los identificadores viajan como ULID, se comparan en RFC 4122 dentro de las consultas, y olvidar la conversión produce un resultado vacío en lugar de un error. Un puerto habría desplazado la conversión; no la habría eliminado.

## La regla de migración

Queda la pregunta que mata las reescrituras: ¿qué hacemos con el código existente, escrito como servicios clásicos de Symfony?

Nada, mientras nadie lo toque. La política está escrita: **CQRS para las escrituras y lecturas nuevas; el código existente migra solo bajo demanda.** Nunca una reescritura masiva en nombre de la homogeneidad.

Porque la homogeneidad no es un resultado de negocio. Reescribir un servicio que funciona para que se parezca a sus vecinos produce riesgo sin producir valor, y es exactamente el tipo de trabajo que se justifica solo, indefinidamente, porque su criterio de parada es estético.

## Lo que dio de sí

- **Nueve contextos con nombre**, cuyo acoplamiento mutuo se lee en las importaciones y no en un diagrama caducado.
- **Veintinueve comandos**, cada uno con un nombre de intención, un manejador único garantizado en el arranque y una frontera de transacción evidente.
- **Un único manejador de consultas**, asumido: las lecturas pasan por los repositorios.
- **Doce archivos de dominio** — nueve excepciones, dos enumeraciones, un rol — es decir, ninguna regla de negocio realmente aislada de Doctrine.
- **Cero reescrituras** del código clásico existente, que sigue funcionando al lado.

## Buenas prácticas

- Adoptar las piezas por separado. El bus de comandos aporta algo sin el resto; los puertos, los agregados y los objetos de valor son compras distintas, cada una con su factura.
- Elegir el valor por defecto más estricto: el bus por defecto es el que muta el estado, y la ausencia de manejador hace fallar el arranque en lugar de la producción.
- Usar los espacios de nombres como detector de acoplamiento y no como barrera: no protegen de nada, hacen visible.
- Escribir la regla de migración con su criterio de parada. Sin él, «homogeneizar la arquitectura» es un trabajo infinito.
- Mirar qué contiene realmente `Domain/` antes de decir que se hace DDD. El recuento es instructivo.

## Puntos de vigilancia

- **La carpeta no es la frontera.** Crear `Domain/`, `Application/`, `Infrastructure/` da una sensación reconfortante de avance medible, y medir una arquitectura por su número de carpetas es la forma más segura de no obtener ninguna de las garantías que sugieren.
- **Veinticuatro de treinta y ocho manejadores dependen del `EntityManager`**: ninguno puede probarse con un repositorio en memoria. La batería de pruebas necesita una base de datos real. Es un coste, está asumido, no es gratis.
- **Las entidades compartidas de Doctrine son el acoplamiento real**, y es invisible en el árbol de carpetas. El día en que dos contextos quieran que la misma tabla diverja, ese será el muro, no la ausencia de puertos.
- **Una regla de negocio duplicada en dos dialectos de consulta acabará divergiendo**, y hoy nada lo detectaría. Es la deuda más concreta de todo lo anterior.
