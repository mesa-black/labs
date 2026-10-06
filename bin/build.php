<?php

declare(strict_types=1);

/*
 * Builds the whole site: content/posts/<lang>/*.md -> public/.
 *
 * Deliberately a script and not a framework. There is no runtime in production:
 * the output is plain files a web server hands over, so the blog cannot be down
 * for an application reason and has no attack surface of its own.
 *
 * The URL scheme mirrors showmetherex.com — French at the root, /en and /es below
 * — so a reader moving between the two sites keeps their bearings.
 *
 * Where the line now sits: the day we need pagination, tags and search on top of
 * this, we stop extending it and move to an off-the-shelf generator.
 *
 *   php bin/build.php            build into public/
 *   php bin/build.php --drafts   include drafts and posts dated in the future
 */

require __DIR__.'/../vendor/autoload.php';

use League\CommonMark\Environment\Environment;
use League\CommonMark\Extension\CommonMark\CommonMarkCoreExtension;
use League\CommonMark\Extension\FrontMatter\FrontMatterExtension;
use League\CommonMark\Extension\FrontMatter\Output\RenderedContentWithFrontMatter;
use League\CommonMark\Extension\SmartPunct\SmartPunctExtension;
use League\CommonMark\MarkdownConverter;
use Twig\Environment as Twig;
use Twig\Loader\FilesystemLoader;
use Twig\TwigFilter;

const ROOT = __DIR__.'/..';

// The sharing cards: GD and two font files, no browser and no ImageMagick.
require __DIR__.'/cards.php';
const OUT = ROOT.'/public';

/** French sits at the root; the others take a prefix, exactly like showmetherex.com. */
const LOCALES = ['fr', 'en', 'es'];
const DEFAULT_LOCALE = 'fr';

$site = [
    'name' => 'BlackMesa Labs',
    'url' => rtrim(getenv('SITE_URL') ?: 'http://localhost:8000', '/'),
];

/** Everything the templates say in their own voice, per language. */
$strings = [
    'fr' => [
        'tagline' => "Notes d'ingénierie : ce qu'on a construit, ce qu'on a cassé, ce qu'on en a tiré.",
        'feed' => 'Flux', 'nav_audit' => 'Audit', 'card_kicker' => 'Notes d’ingénierie', 'minutes' => 'min', 'reading' => 'min de lecture',
        'draft' => 'brouillon', 'elsewhere' => 'sur Show me the REX',
        'back' => 'Tous les articles', 'language' => 'Langue',
        'crossover_pointer' => 'Publié sur Show me the REX',
        'crossover_also' => 'Aussi publié comme REX',
        'crossover_read' => 'Lire le retour d’expérience complet',
        'crossover_see' => 'Voir la fiche REX',
        'crossover_note' => 'Show me the REX est la plateforme de retours d’expérience Tech, data et IA que nous éditons.',
        'footer_agency' => 'BlackMesa — conseil et ingénierie logicielle.',
        'footer_smtr' => 'Nos retours d’expérience clients sont publiés sur',
        'footer_audit' => 'Inventaire cryptographique de ce site, signé',
        'footer_audit_hint' => 'vérifiable sans nous',
    ],
    'en' => [
        'tagline' => 'Engineering notes: what we built, what we broke, what we took away.',
        'feed' => 'Feed', 'nav_audit' => 'Audit', 'card_kicker' => 'Engineering notes', 'minutes' => 'min', 'reading' => 'min read',
        'draft' => 'draft', 'elsewhere' => 'on Show me the REX',
        'back' => 'All posts', 'language' => 'Language',
        'crossover_pointer' => 'Published on Show me the REX',
        'crossover_also' => 'Also published as a case study',
        'crossover_read' => 'Read the full case study',
        'crossover_see' => 'See the case study',
        'crossover_note' => 'Show me the REX is the Tech, data and AI case-study platform we run.',
        'footer_agency' => 'BlackMesa — software consulting and engineering.',
        'footer_smtr' => 'Our client case studies are published on',
        'footer_audit' => 'This site’s cryptographic inventory, signed',
        'footer_audit_hint' => 'verifiable without us',
    ],
    'es' => [
        'tagline' => 'Notas de ingeniería: lo que construimos, lo que rompimos, lo que aprendimos.',
        'feed' => 'Feed', 'nav_audit' => 'Auditoría', 'card_kicker' => 'Notas de ingeniería', 'minutes' => 'min', 'reading' => 'min de lectura',
        'draft' => 'borrador', 'elsewhere' => 'en Show me the REX',
        'back' => 'Todos los artículos', 'language' => 'Idioma',
        'crossover_pointer' => 'Publicado en Show me the REX',
        'crossover_also' => 'También publicado como caso',
        'crossover_read' => 'Leer el caso completo',
        'crossover_see' => 'Ver el caso',
        'crossover_note' => 'Show me the REX es la plataforma de casos de Tech, datos e IA que editamos.',
        'footer_agency' => 'BlackMesa — consultoría e ingeniería de software.',
        'footer_smtr' => 'Nuestros casos de clientes se publican en',
        'footer_audit' => 'Inventario criptográfico de este sitio, firmado',
        'footer_audit_hint' => 'verificable sin nosotros',
    ],
];

$months = [
    'fr' => [1 => 'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'],
    'en' => [1 => 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
    'es' => [1 => 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'],
];

$withDrafts = \in_array('--drafts', $argv, true);

// --as-of=YYYY-MM-DD builds the site as it will be on that day. That is what
// lets future publications be prepared from the workstation and checked before
// they come out: the server builds nothing, it switches a link.
$asOf = 'today';
foreach ($argv as $arg) {
    if (str_starts_with($arg, '--as-of=')) {
        $asOf = substr($arg, 8);
        if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $asOf) !== 1) {
            $fail("--as-of attend une date AAAA-MM-JJ, reçu \"$asOf\"");
        }
    }
}
// Fixed once and for all: a build that straddles midnight must not publish half
// the translations of a scheduled piece.
$now = new DateTimeImmutable($asOf.' 23:59:59');

// --release-dates builds nothing: it lists the publication dates still ahead,
// one per line. The deployment uses it to know how many dated versions it has
// to prepare.
if (\in_array('--release-dates', $argv, true)) {
    $dates = [];
    foreach (glob(ROOT.'/content/posts/*/*.md') ?: [] as $file) {
        $head = (string) file_get_contents($file, false, null, 0, 2048);
        if (preg_match('/^draft:\s*true\s*$/m', $head) === 1) {
            continue;
        }
        if (preg_match('/^date:\s*(\d{4}-\d{2}-\d{2})/m', $head, $m) === 1 && $m[1] > date('Y-m-d')) {
            $dates[$m[1]] = true;
        }
    }
    $dates = array_keys($dates);
    sort($dates);
    echo implode("\n", $dates), $dates === [] ? '' : "\n";
    exit(0);
}

$fail = static function (string $message): void {
    fwrite(\STDERR, "✗ $message\n");
    exit(1);
};

// ---------------------------------------------------------------- markdown
$env = new Environment(['html_input' => 'allow', 'allow_unsafe_links' => false]);
$env->addExtension(new CommonMarkCoreExtension());
$env->addExtension(new FrontMatterExtension());
$env->addExtension(new SmartPunctExtension());
$markdown = new MarkdownConverter($env);


/**
 * Links the FIRST mention of "Show me the REX" in a piece to the platform, in
 * the reader's language. Not every one: ten identical links on a page reads
 * badly, and search engines see stuffing.
 *
 * The HTML is walked with tags and text kept apart, so a link is never written
 * inside a link or inside a code block.
 */
function linkBrandOnce(string $html, string $locale): string
{
    $url = 'https://showmetherex.com'.($locale === DEFAULT_LOCALE ? '/' : "/$locale/");
    $parts = preg_split('/(<[^>]+>)/', $html, -1, \PREG_SPLIT_DELIM_CAPTURE) ?: [];
    $inside = 0;
    $done = false;

    foreach ($parts as $i => $part) {
        if ($part === '') {
            continue;
        }

        if ($part[0] === '<') {
            if (preg_match('#^<(a|code|pre)[\s>]#i', $part) === 1) {
                ++$inside;
            } elseif (preg_match('#^</(a|code|pre)>#i', $part) === 1) {
                $inside = max(0, $inside - 1);
            }

            continue;
        }

        if ($done || $inside > 0) {
            continue;
        }

        $parts[$i] = preg_replace_callback(
            '/Show me the REX/i',
            static function (array $m) use ($url, &$done): string {
                $done = true;

                return sprintf('<a href="%s" target="_blank" rel="noopener">%s</a>', $url, $m[0]);
            },
            $part,
            1,
        );
    }

    return implode('', $parts);
}

/**
 * Opens anything that leaves this site in a new tab.
 *
 * Reading a piece and following a link out of it are two different intents, and
 * a reader who wanted the second rarely wanted to lose the first. Navigation
 * inside the blog is untouched: moving from the home page to a piece, or back,
 * is the same intent continuing, and a new tab per article would be a mess of
 * tabs within a minute.
 *
 * `rel="noopener"` because the opened page must not reach back into this one.
 * Not `noreferrer`: the platform these links mostly point at deserves to see
 * where its readers came from, and stripping that would hide our own traffic
 * from ourselves.
 */
function externalLinksInNewTab(string $html, string $site): string
{
    $host = parse_url($site, \PHP_URL_HOST) ?: '';

    return (string) preg_replace_callback(
        '#<a\s([^>]*?)href="(https?://[^"]+)"([^>]*)>#i',
        static function (array $m) use ($host): string {
            // Already carrying a target, or pointing back at this site: leave it.
            if (stripos($m[1].$m[3], 'target=') !== false
                || parse_url($m[2], \PHP_URL_HOST) === $host) {
                return $m[0];
            }

            return sprintf('<a %shref="%s"%s target="_blank" rel="noopener">', $m[1], $m[2], $m[3]);
        },
        $html,
    );
}

// ---------------------------------------------------------------- read posts
$byLocale = array_fill_keys(LOCALES, []);

foreach (LOCALES as $locale) {
    foreach (glob(ROOT."/content/posts/$locale/*.md") ?: [] as $file) {
        $rendered = $markdown->convert(file_get_contents($file));
        $meta = $rendered instanceof RenderedContentWithFrontMatter ? $rendered->getFrontMatter() : [];
        $name = basename($file);

        foreach (['title', 'date', 'key'] as $required) {
            if (empty($meta[$required])) {
                $fail("$locale/$name: missing \"$required\" in the front matter");
            }
        }

        $draft = (bool) ($meta['draft'] ?? false);
        if ($draft && !$withDrafts) {
            continue;
        }

        $date = \is_int($meta['date'])
            ? (new DateTimeImmutable())->setTimestamp($meta['date'])
            : new DateTimeImmutable((string) $meta['date']);

        // The date is a publication date: a piece dated in the future waits for
        // its day. That is what allows writing ahead without keeping a "ready
        // but not published" state anywhere but in the file itself. It comes out
        // on the first build run on or after that date.
        if ($date > $now && !$withDrafts) {
            continue;
        }

        $rexUrl = (string) ($meta['rex'] ?? '');
        $pointer = (bool) ($meta['pointer'] ?? false);
        if ($pointer && $rexUrl === '') {
            $fail("$locale/$name: a pointer post needs a \"rex\" URL");
        }

        // A table is the one block that can outgrow a phone screen: give each its
        // own scroll container rather than letting the whole page slide sideways.
        $html = str_replace(['<table>', '</table>'], ['<div class="scroll"><table>', '</table></div>'], (string) $rendered);
        $html = linkBrandOnce($html, $locale);
        $html = externalLinksInNewTab($html, $site['url']);

        $slug = (string) ($meta['slug'] ?? preg_replace('/^\d{4}-\d{2}-\d{2}-/', '', basename($file, '.md')));

        $byLocale[$locale][] = [
            'key' => (string) $meta['key'],
            'slug' => $slug,
            'url' => ($locale === DEFAULT_LOCALE ? '' : "/$locale")."/$slug/",
            'title' => (string) $meta['title'],
            'standfirst' => (string) ($meta['standfirst'] ?? ''),
            'date' => $date,
            'draft' => $draft,
            'rex' => $rexUrl,
            'pointer' => $pointer,
            'canonical' => $pointer ? $rexUrl : '',
            'html' => $html,
            // Reading time from the rendered text: the markdown still carries
            // syntax the reader never sees.
            'words' => $words = str_word_count(strip_tags($html)),
            'minutes' => max(1, (int) round($words / 200)),
        ];
    }

    usort($byLocale[$locale], static fn (array $a, array $b): int => $b['date'] <=> $a['date']);
}

if ($byLocale[DEFAULT_LOCALE] === []) {
    $fail('no post to build (use --drafts to include drafts)');
}

// Which languages a given piece exists in, so a page can offer the others and
// declare its hreflang alternates.
$translations = [];
foreach ($byLocale as $locale => $posts) {
    foreach ($posts as $post) {
        $translations[$post['key']][$locale] = $post['url'];
    }
}

// ---------------------------------------------------------------- render
$twig = new Twig(new FilesystemLoader(ROOT.'/templates'), [
    'autoescape' => 'html',
    'strict_variables' => true,
]);
$twig->addFilter(new TwigFilter('long_date', static function (DateTimeImmutable $d, string $locale) use ($months): string {
    $day = $d->format('j');
    $month = $months[$locale][(int) $d->format('n')];
    $year = $d->format('Y');

    return match ($locale) {
        'en' => "$month $day, $year",
        'es' => "$day de $month de $year",
        default => "$day $month $year",
    };
}));

$write = static function (string $path, string $html): void {
    $full = OUT.'/'.ltrim($path, '/');
    @mkdir(\dirname($full), 0o755, true);
    file_put_contents($full, $html);
    echo '  ', str_pad($path, 48), number_format(\strlen($html) / 1024, 1), " KB\n";
};

// A fresh public/ every time: no stale page survives a renamed slug.
if (is_dir(OUT)) {
    foreach (new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator(OUT, FilesystemIterator::SKIP_DOTS),
        RecursiveIteratorIterator::CHILD_FIRST
    ) as $item) {
        $item->isDir() ? @rmdir($item->getPathname()) : @unlink($item->getPathname());
    }
}
@mkdir(OUT, 0o755, true);

/** Every page of every language, for one sitemap covering the whole site. */
$pages = [];
$homes = [];
foreach (LOCALES as $locale) {
    if ($byLocale[$locale] !== []) {
        $homes[$locale] = $locale === DEFAULT_LOCALE ? '/' : "/$locale/";
    }
}

foreach (LOCALES as $locale) {
    $posts = $byLocale[$locale];
    if ($posts === []) {
        continue;
    }

    $prefix = $locale === DEFAULT_LOCALE ? '' : "/$locale";
    $context = [
        'site' => $site,
        'locale' => $locale,
        'locales' => LOCALES,
        't' => $strings[$locale],
        'home' => $prefix.'/',
        'feed_url' => $prefix.'/feed.xml',
        // The platform is trilingual too: send the reader to their own language
        // rather than landing them in French.
        'audit_published' => is_file(ROOT.'/assets/audit/report.html'),
        'audit_url' => '/audit'.($locale === DEFAULT_LOCALE ? '' : "/$locale").'/report.html',
        'smtr_url' => 'https://showmetherex.com'.($locale === DEFAULT_LOCALE ? '/' : "/$locale/"),
        'translations' => $translations,
    ];

    echo "Building $locale (", \count($posts), " post(s))\n";
    $write(ltrim($prefix.'/index.html', '/'), $twig->render('index.html.twig', $context + ['posts' => $posts, 'page_url' => $prefix.'/']));
    $pages[] = ['url' => $prefix.'/', 'lastmod' => $posts[0]['date']->format('Y-m-d'), 'alternates' => $homes];

    foreach ($posts as $post) {
        // The sharing card, drawn here rather than hand-made: one per piece and
        // per language, carrying that piece's title. A single house card would
        // say the same thing about every article, and no card at all is an
        // empty thumbnail on every platform that unfurls a link.
        $card = '/cards/'.$locale.'/'.basename(rtrim($post['url'], '/')).'.png';
        @mkdir(\dirname(OUT.$card), 0o755, true);
        draw([
            'title' => $post['title'],
            'kicker' => $strings[$locale]['card_kicker'],
            'footer' => $twig->getFilter('long_date')->getCallable()($post['date'], $locale)
                .' · '.$post['minutes'].' '.$strings[$locale]['reading'],
            'out' => OUT.$card,
        ]);

        $write(ltrim($post['url'], '/').'index.html', $twig->render('post.html.twig', $context + ['post' => $post, 'page_url' => $post['url'], 'og_image' => $card]));
        $pages[] = ['url' => $post['url'], 'lastmod' => $post['date']->format('Y-m-d'), 'alternates' => $translations[$post['key']]];
    }

    $write(ltrim($prefix.'/feed.xml', '/'), $twig->render('feed.xml.twig', $context + ['posts' => \array_slice($posts, 0, 20)]));
}

// Crawlers: one sitemap for the whole site, and a robots.txt that says so.
$write('sitemap.xml', $twig->render('sitemap.xml.twig', ['site' => $site, 'pages' => $pages]));
$write('robots.txt', implode("\n", [
    'User-agent: *',
    'Allow: /',
    '',
    '# Answer engines are welcome: being quoted is the point of writing this.',
    '# Flip these to Disallow to opt out.',
    'User-agent: GPTBot',
    'Allow: /',
    'User-agent: ClaudeBot',
    'Allow: /',
    'User-agent: PerplexityBot',
    'Allow: /',
    '',
    'Sitemap: '.$site['url'].'/sitemap.xml',
    '',
]));
$write('404.html', $twig->render('404.html.twig', [
    'site' => $site, 'locale' => DEFAULT_LOCALE, 'locales' => LOCALES,
    't' => $strings[DEFAULT_LOCALE], 'home' => '/', 'feed_url' => '/feed.xml',
    'audit_published' => is_file(ROOT.'/assets/audit/report.html'),
    'audit_url' => '/audit/report.html',
    'smtr_url' => 'https://showmetherex.com/',
    'translations' => $translations, 'page_url' => '/404.html',
]));

copy(ROOT.'/assets/style.css', OUT.'/style.css');
echo '  ', str_pad('style.css', 48), number_format(filesize(OUT.'/style.css') / 1024, 1), " KB\n";

// The site's cryptographic inventory, produced by `make audit` and copied as
// is. These are self-contained signed documents: rebuilding them here would take
// them outside the scope of the signature, which covers findings and not a
// layout.
if (is_dir(ROOT.'/assets/audit')) {
    // One subdirectory per language beyond the default, so the copy walks.
    $walk = static function (string $from, string $to) use (&$walk): void {
        @mkdir($to, 0o755, true);
        foreach (glob($from.'/*') ?: [] as $artefact) {
            $target = $to.'/'.basename($artefact);
            if (is_dir($artefact)) {
                $walk($artefact, $target);

                continue;
            }
            copy($artefact, $target);
            echo '  ', str_pad(ltrim(str_replace(OUT, '', $target), '/'), 48),
                number_format(filesize($artefact) / 1024, 1), " KB\n";
        }
    };
    $walk(ROOT.'/assets/audit', OUT.'/audit');
}

echo "\n✓ public/ is ready", $withDrafts ? ' (drafts included — do not deploy)' : '', "\n";
