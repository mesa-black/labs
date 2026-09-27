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
 *   php bin/build.php --drafts   include posts marked draft: true
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
        'feed' => 'Flux', 'minutes' => 'min', 'reading' => 'min de lecture',
        'draft' => 'brouillon', 'elsewhere' => 'sur Show me the REX',
        'back' => 'Tous les articles', 'language' => 'Langue',
        'crossover_pointer' => 'Publié sur Show me the REX',
        'crossover_also' => 'Aussi publié comme REX',
        'crossover_read' => 'Lire le retour d’expérience complet',
        'crossover_see' => 'Voir la fiche REX',
        'crossover_note' => 'Show me the REX est la plateforme de retours d’expérience Tech, data et IA que nous éditons.',
        'footer_agency' => 'BlackMesa — conseil et ingénierie logicielle.',
        'footer_smtr' => 'Nos retours d’expérience clients sont publiés sur',
    ],
    'en' => [
        'tagline' => 'Engineering notes: what we built, what we broke, what we took away.',
        'feed' => 'Feed', 'minutes' => 'min', 'reading' => 'min read',
        'draft' => 'draft', 'elsewhere' => 'on Show me the REX',
        'back' => 'All posts', 'language' => 'Language',
        'crossover_pointer' => 'Published on Show me the REX',
        'crossover_also' => 'Also published as a case study',
        'crossover_read' => 'Read the full case study',
        'crossover_see' => 'See the case study',
        'crossover_note' => 'Show me the REX is the Tech, data and AI case-study platform we run.',
        'footer_agency' => 'BlackMesa — software consulting and engineering.',
        'footer_smtr' => 'Our client case studies are published on',
    ],
    'es' => [
        'tagline' => 'Notas de ingeniería: lo que construimos, lo que rompimos, lo que aprendimos.',
        'feed' => 'Feed', 'minutes' => 'min', 'reading' => 'min de lectura',
        'draft' => 'borrador', 'elsewhere' => 'en Show me the REX',
        'back' => 'Todos los artículos', 'language' => 'Idioma',
        'crossover_pointer' => 'Publicado en Show me the REX',
        'crossover_also' => 'También publicado como caso',
        'crossover_read' => 'Leer el caso completo',
        'crossover_see' => 'Ver el caso',
        'crossover_note' => 'Show me the REX es la plataforma de casos de Tech, datos e IA que editamos.',
        'footer_agency' => 'BlackMesa — consultoría e ingeniería de software.',
        'footer_smtr' => 'Nuestros casos de clientes se publican en',
    ],
];

$months = [
    'fr' => [1 => 'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'],
    'en' => [1 => 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
    'es' => [1 => 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'],
];

$withDrafts = \in_array('--drafts', $argv, true);

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

        $rexUrl = (string) ($meta['rex'] ?? '');
        $pointer = (bool) ($meta['pointer'] ?? false);
        if ($pointer && $rexUrl === '') {
            $fail("$locale/$name: a pointer post needs a \"rex\" URL");
        }

        // A table is the one block that can outgrow a phone screen: give each its
        // own scroll container rather than letting the whole page slide sideways.
        $html = str_replace(['<table>', '</table>'], ['<div class="scroll"><table>', '</table></div>'], (string) $rendered);

        $slug = (string) ($meta['slug'] ?? preg_replace('/^\d{4}-\d{2}-\d{2}-/', '', basename($file, '.md')));

        $byLocale[$locale][] = [
            'key' => (string) $meta['key'],
            'slug' => $slug,
            'url' => ($locale === DEFAULT_LOCALE ? '' : "/$locale")."/$slug/",
            'title' => (string) $meta['title'],
            'standfirst' => (string) ($meta['standfirst'] ?? ''),
            'date' => \is_int($meta['date'])
                ? (new DateTimeImmutable())->setTimestamp($meta['date'])
                : new DateTimeImmutable((string) $meta['date']),
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
        'translations' => $translations,
    ];

    echo "Building $locale (", \count($posts), " post(s))\n";
    $write(ltrim($prefix.'/index.html', '/'), $twig->render('index.html.twig', $context + ['posts' => $posts, 'page_url' => $prefix.'/']));
    $pages[] = ['url' => $prefix.'/', 'lastmod' => $posts[0]['date']->format('Y-m-d'), 'alternates' => $homes];

    foreach ($posts as $post) {
        $write(ltrim($post['url'], '/').'index.html', $twig->render('post.html.twig', $context + ['post' => $post, 'page_url' => $post['url']]));
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
    'translations' => $translations, 'page_url' => '/404.html',
]));

copy(ROOT.'/assets/style.css', OUT.'/style.css');
echo '  ', str_pad('style.css', 48), number_format(filesize(OUT.'/style.css') / 1024, 1), " KB\n";

echo "\n✓ public/ is ready", $withDrafts ? ' (drafts included — do not deploy)' : '', "\n";
