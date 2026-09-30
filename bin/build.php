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

// --as-of=AAAA-MM-JJ construit le site tel qu'il sera ce jour-là. C'est ce qui
// permet de préparer les parutions futures depuis le poste et de les vérifier
// avant qu'elles ne sortent : le serveur ne construit rien, il bascule.
$asOf = 'today';
foreach ($argv as $arg) {
    if (str_starts_with($arg, '--as-of=')) {
        $asOf = substr($arg, 8);
        if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $asOf) !== 1) {
            $fail("--as-of attend une date AAAA-MM-JJ, reçu \"$asOf\"");
        }
    }
}
// Figé une fois pour toutes : un build qui chevauche minuit ne doit pas publier
// la moitié des traductions d'un article programmé.
$now = new DateTimeImmutable($asOf.' 23:59:59');

// --release-dates ne construit rien : il liste les dates de parution encore à
// venir, une par ligne. Le déploiement s'en sert pour savoir combien de
// versions datées il doit préparer.
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
 * Lie la PREMIÈRE mention de « Show me the REX » d'un article vers la plateforme,
 * dans la langue du lecteur. Pas toutes : dix fois le même lien dans une page se
 * lit mal et les moteurs y voient du bourrage.
 *
 * Le HTML est parcouru en séparant balises et texte, pour ne jamais écrire un
 * lien dans un lien, ni à l'intérieur d'un bloc de code.
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

                return sprintf('<a href="%s">%s</a>', $url, $m[0]);
            },
            $part,
            1,
        );
    }

    return implode('', $parts);
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

        // La date est une date de parution : un article daté du futur attend son
        // jour. C'est ce qui permet d'écrire à l'avance sans tenir un état
        // « prêt mais pas publié » ailleurs que dans le fichier lui-même. Il
        // sort au premier build effectué à partir de cette date.
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
        // La plateforme est trilingue elle aussi : on renvoie le lecteur dans sa
        // langue plutôt que de le faire atterrir en français.
        'smtr_url' => 'https://showmetherex.com'.($locale === DEFAULT_LOCALE ? '/' : "/$locale/"),
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
    'smtr_url' => 'https://showmetherex.com/',
    'translations' => $translations, 'page_url' => '/404.html',
]));

copy(ROOT.'/assets/style.css', OUT.'/style.css');
echo '  ', str_pad('style.css', 48), number_format(filesize(OUT.'/style.css') / 1024, 1), " KB\n";

echo "\n✓ public/ is ready", $withDrafts ? ' (drafts included — do not deploy)' : '', "\n";
