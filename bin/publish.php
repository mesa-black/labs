<?php

declare(strict_types=1);

/*
 * Passe un article de brouillon à publié — dans toutes ses langues d'un coup,
 * parce qu'un article oublié en brouillon dans une seule langue est le genre
 * d'erreur qu'on ne voit que des semaines plus tard.
 *
 *   php bin/publish.php                 liste les brouillons
 *   php bin/publish.php <clé>           publie toutes les langues de cet article
 *   php bin/publish.php <clé> --draft   remet en brouillon
 *
 * Le front matter est lu à la ligne plutôt que parsé : on ne touche qu'à `draft`
 * et `key`, et le reste du fichier doit ressortir octet pour octet identique.
 */

const ROOT = __DIR__.'/..';

/** @return list<array{file: string, locale: string, key: string, title: string, draft: bool}> */
function posts(): array
{
    $found = [];

    foreach (glob(ROOT.'/content/posts/*/*.md') ?: [] as $file) {
        $lines = file($file, \FILE_IGNORE_NEW_LINES);
        if (($lines[0] ?? '') !== '---') {
            continue;
        }

        $meta = ['key' => '', 'title' => '', 'draft' => false];
        for ($i = 1; $i < \count($lines) && $lines[$i] !== '---'; ++$i) {
            if (preg_match('/^(key|title|draft):\s*(.*)$/', $lines[$i], $m) === 1) {
                $meta[$m[1]] = $m[1] === 'draft' ? trim($m[2]) === 'true' : trim($m[2], " \"'");
            }
        }

        $found[] = $meta + ['file' => $file, 'locale' => basename(\dirname($file))];
    }

    return $found;
}

$all = posts();
$key = $argv[1] ?? null;
$toDraft = \in_array('--draft', $argv, true);

// ---------------------------------------------------------------- listing
if ($key === null || str_starts_with($key, '--')) {
    $drafts = array_filter($all, static fn (array $p): bool => $p['draft']);

    if ($drafts === []) {
        echo "Aucun brouillon.\n";
        exit(0);
    }

    $byKey = [];
    foreach ($drafts as $p) {
        $byKey[$p['key']][] = $p;
    }

    echo "Brouillons :\n\n";
    foreach ($byKey as $k => $group) {
        $locales = implode(', ', array_column($group, 'locale'));
        // Titre français de préférence : c'est la langue dans laquelle on écrit.
        $fr = array_filter($group, static fn (array $p): bool => $p['locale'] === 'fr');
        $title = ($fr !== [] ? reset($fr) : $group[0])['title'];
        printf("  %-34s %s\n", $k, $title);
        printf("  %-34s langues : %s\n\n", '', $locales);
    }
    echo "Pour publier :  make publish KEY=<clé>\n";
    exit(0);
}

// ---------------------------------------------------------------- bascule
$matching = array_filter($all, static fn (array $p): bool => $p['key'] === $key);

if ($matching === []) {
    fwrite(\STDERR, "✗ aucun article avec la clé \"$key\".\n   `php bin/publish.php` liste les brouillons.\n");
    exit(1);
}

$changed = 0;
foreach ($matching as $post) {
    if ($post['draft'] === $toDraft) {
        printf("  %s/%s — déjà %s\n", $post['locale'], basename($post['file']), $toDraft ? 'en brouillon' : 'publié');
        continue;
    }

    $lines = file($post['file'], \FILE_IGNORE_NEW_LINES);
    $end = array_search('---', \array_slice($lines, 1), true) + 1;

    if ($toDraft) {
        array_splice($lines, $end, 0, 'draft: true');
    } else {
        foreach ($lines as $i => $line) {
            if ($i <= $end && preg_match('/^draft:\s*true\s*$/', $line) === 1) {
                unset($lines[$i]);
                break;
            }
        }
    }

    file_put_contents($post['file'], implode("\n", $lines)."\n");
    printf("  %s/%s → %s\n", $post['locale'], basename($post['file']), $toDraft ? 'brouillon' : 'publié');
    ++$changed;
}

if ($changed === 0) {
    echo "\nRien à faire.\n";
    exit(0);
}

printf("\n✓ %s : %d fichier(s) %s\n", $key, $changed, $toDraft ? 'remis en brouillon' : 'publié(s)');

// Les langues manquantes valent un avertissement : publier un article dans une
// seule langue, c'est afficher les autres en grisé sans s'en rendre compte.
$locales = array_column($matching, 'locale');
if ($missing = array_diff(['fr', 'en', 'es'], $locales)) {
    printf("⚠ pas de version : %s\n", implode(', ', $missing));
}
