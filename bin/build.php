<?php

declare(strict_types=1);

/*
 * Builds the whole site: content/posts/*.md -> public/*.html.
 *
 * Deliberately a script and not a framework. There is no runtime in production:
 * the output is plain files a web server hands over, so the blog cannot be down
 * for an application reason and has no attack surface of its own.
 *
 * The day we need pagination, tags, translations and search, we stop extending
 * this and move to an off-the-shelf generator. Until then, 150 lines beat a
 * dependency.
 *
 *   php bin/build.php            build into public/
 *   php bin/build.php --drafts   include posts marked draft: true
 */

require __DIR__.'/../vendor/autoload.php';

use League\CommonMark\Environment\Environment;
use League\CommonMark\Extension\CommonMark\CommonMarkCoreExtension;
use League\CommonMark\Extension\FrontMatter\FrontMatterExtension;
use League\CommonMark\Extension\SmartPunct\SmartPunctExtension;
use League\CommonMark\MarkdownConverter;
use League\CommonMark\Extension\FrontMatter\Output\RenderedContentWithFrontMatter;
use Twig\Environment as Twig;
use Twig\Loader\FilesystemLoader;

const ROOT = __DIR__.'/..';
const OUT = ROOT.'/public';

$site = [
    'name' => 'BlackMesa Labs',
    'tagline' => "Notes d'ingénierie : ce qu'on a construit, ce qu'on a cassé, ce qu'on en a tiré.",
    'url' => getenv('SITE_URL') ?: 'http://localhost:8000',
    'locale' => 'fr',
];

$withDrafts = \in_array('--drafts', $argv, true);

// ---------------------------------------------------------------- markdown
$env = new Environment([
    'html_input' => 'allow',          // our own content; we are the only authors
    'allow_unsafe_links' => false,
]);
$env->addExtension(new CommonMarkCoreExtension());
$env->addExtension(new FrontMatterExtension());
$env->addExtension(new SmartPunctExtension());   // real quotes and dashes, for free
$markdown = new MarkdownConverter($env);

// ---------------------------------------------------------------- read posts
$posts = [];
foreach (glob(ROOT.'/content/posts/*.md') ?: [] as $file) {
    $rendered = $markdown->convert(file_get_contents($file));
    $meta = $rendered instanceof RenderedContentWithFrontMatter ? $rendered->getFrontMatter() : [];

    foreach (['title', 'date'] as $required) {
        if (empty($meta[$required])) {
            fwrite(\STDERR, sprintf("✗ %s: missing \"%s\" in the front matter\n", basename($file), $required));
            exit(1);
        }
    }

    $draft = (bool) ($meta['draft'] ?? false);
    if ($draft && !$withDrafts) {
        continue;
    }

    $html = (string) $rendered;
    $posts[] = [
        'slug' => $meta['slug'] ?? preg_replace('/^\d{4}-\d{2}-\d{2}-/', '', basename($file, '.md')),
        'title' => (string) $meta['title'],
        'standfirst' => (string) ($meta['standfirst'] ?? ''),
        // Symfony's YAML parser turns an unquoted date into a timestamp, a quoted
        // one into a string. Accept both rather than dictating how to write it.
        'date' => \is_int($meta['date'])
            ? (new DateTimeImmutable())->setTimestamp($meta['date'])
            : new DateTimeImmutable((string) $meta['date']),
        'draft' => $draft,
        'html' => $html,
        // Reading time from the rendered text: the only honest source, since the
        // markdown still carries syntax the reader never sees.
        'minutes' => max(1, (int) round(str_word_count(strip_tags($html)) / 200)),
    ];
}

usort($posts, static fn (array $a, array $b): int => $b['date'] <=> $a['date']);

if ($posts === []) {
    fwrite(\STDERR, "✗ no post to build (use --drafts to include drafts)\n");
    exit(1);
}

// ---------------------------------------------------------------- render
$twig = new Twig(new FilesystemLoader(ROOT.'/templates'), [
    'autoescape' => 'html',
    'strict_variables' => true,
]);
$twig->addFilter(new \Twig\TwigFilter('date_fr', static function (DateTimeImmutable $d): string {
    $months = [1 => 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];

    return $d->format('j').' '.$months[(int) $d->format('n')].' '.$d->format('Y');
}));

$write = static function (string $path, string $html): void {
    $full = OUT.'/'.ltrim($path, '/');
    @mkdir(\dirname($full), 0o755, true);
    file_put_contents($full, $html);
    echo '  ', str_pad($path, 46), number_format(\strlen($html) / 1024, 1), " KB\n";
};

// A fresh public/ every time: no stale page can survive a renamed slug.
if (is_dir(OUT)) {
    foreach (new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator(OUT, FilesystemIterator::SKIP_DOTS),
        RecursiveIteratorIterator::CHILD_FIRST
    ) as $item) {
        $item->isDir() ? @rmdir($item->getPathname()) : @unlink($item->getPathname());
    }
}
@mkdir(OUT, 0o755, true);

echo "Building ", \count($posts), " post(s)\n";
$write('index.html', $twig->render('index.html.twig', ['site' => $site, 'posts' => $posts]));

foreach ($posts as $post) {
    $write($post['slug'].'/index.html', $twig->render('post.html.twig', ['site' => $site, 'post' => $post]));
}

$write('feed.xml', $twig->render('feed.xml.twig', ['site' => $site, 'posts' => \array_slice($posts, 0, 20)]));
copy(ROOT.'/assets/style.css', OUT.'/style.css');
echo '  ', str_pad('style.css', 46), number_format(filesize(OUT.'/style.css') / 1024, 1), " KB\n";

echo "\n✓ public/ is ready", $withDrafts ? " (drafts included — do not deploy)" : '', "\n";
