<?php

declare(strict_types=1);

/*
 * Moves a piece from draft to published — in every one of its languages at
 * once, because a piece left in draft in a single language is the kind of
 * mistake nobody sees for weeks.
 *
 *   php bin/publish.php                 lists the drafts
 *   php bin/publish.php <key>           publishes every language of that piece
 *   php bin/publish.php <key> --draft   puts it back to draft
 *
 * The front matter is read line by line rather than parsed: only `draft` and
 * `key` are touched, and the rest of the file has to come out identical byte
 * for byte.
 */

const ROOT = __DIR__.'/..';

/** @return list<array{file: string, locale: string, key: string, title: string, draft: bool, date: string}> */
function posts(): array
{
    $found = [];

    foreach (glob(ROOT.'/content/posts/*/*.md') ?: [] as $file) {
        $lines = file($file, \FILE_IGNORE_NEW_LINES);
        if (($lines[0] ?? '') !== '---') {
            continue;
        }

        $meta = ['key' => '', 'title' => '', 'draft' => false, 'date' => ''];
        for ($i = 1; $i < \count($lines) && $lines[$i] !== '---'; ++$i) {
            if (preg_match('/^(key|title|draft|date):\s*(.*)$/', $lines[$i], $m) === 1) {
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

    // A piece dated in the future is not a draft: it is written, reviewed, and
    // waiting for its date. Confusing the two means rewriting it.
    $today = date('Y-m-d');
    $scheduled = array_filter($all, static fn (array $p): bool => !$p['draft'] && $p['date'] > $today);
    if ($scheduled !== []) {
        $byDate = [];
        foreach ($scheduled as $p) {
            $byDate[$p['date']][$p['key']][] = $p['locale'];
        }
        ksort($byDate);
        echo "Programmés :\n\n";
        foreach ($byDate as $day => $keys) {
            foreach ($keys as $k => $locales) {
                printf("  %-34s %s — langues : %s\n", $k, $day, implode(', ', $locales));
            }
        }
        echo "\n  Ils sortiront au premier `make deploy` fait à partir de leur date.\n\n";
    }

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
        // The French title by preference: that is the language we write in.
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

// A missing language is worth a warning: publishing a piece in one language
// only means showing the others greyed out without noticing.
$locales = array_column($matching, 'locale');
if ($missing = array_diff(['fr', 'en', 'es'], $locales)) {
    printf("⚠ pas de version : %s\n", implode(', ', $missing));
}
