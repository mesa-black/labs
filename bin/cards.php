<?php

declare(strict_types=1);

/*
 * One sharing card per piece, per language, drawn at build time.
 *
 * Without an og:image a link pasted on LinkedIn comes out with an empty
 * thumbnail, which is the difference between a post that is read and a post
 * that is scrolled past. The obvious fix — one house card for the whole site —
 * would say the same thing about every article, so the card carries the title
 * of the piece it belongs to, in the language of the page that links it.
 *
 * Drawn with GD and two font files rather than a browser or ImageMagick: this
 * repository has no build chain on the server and no appetite for one on the
 * workstation either. The two faces are the site's own, used for the jobs the
 * stylesheet gives them — the serif carries what is written, the monospace
 * carries what a machine says about it. There is no third element: no hexagon,
 * no gradient, no shadow. A card is a quiet object or it is a template.
 */

// Guarded rather than declared: build.php defines it before requiring this
// file, and a warning printed in the middle of a deployment is noise somebody
// learns to ignore.
\defined('ROOT') || \define('ROOT', __DIR__.'/..');

const W = 1200;
const H = 630;
const PAD = 76;

/** @return array{0:int,1:int,2:int} */
function rgb(string $hex): array
{
    return [
        (int) hexdec(substr($hex, 1, 2)),
        (int) hexdec(substr($hex, 3, 2)),
        (int) hexdec(substr($hex, 5, 2)),
    ];
}

/**
 * Letter by letter, because GD has no letter-spacing and the site's small caps
 * are tracked. Drawing the string in one call would make the one typographic
 * detail that says "designed" disappear.
 */
function tracked(\GdImage $im, int $colour, string $font, float $size, int $x, int $y, string $text, float $track): int
{
    foreach (preg_split('//u', $text, -1, \PREG_SPLIT_NO_EMPTY) ?: [] as $glyph) {
        imagettftext($im, $size, 0, $x, $y, $colour, $font, $glyph);
        $box = imagettfbbox($size, 0, $font, $glyph);
        $x += (int) round(($box[2] - $box[0]) + $track);
    }

    return $x;
}

/** @return list<string> */
function wrap(string $text, string $font, float $size, int $width): array
{
    $lines = [];
    $line = '';
    foreach (explode(' ', $text) as $word) {
        $try = $line === '' ? $word : $line.' '.$word;
        $box = imagettfbbox($size, 0, $font, $try);
        if ($box[2] - $box[0] > $width && $line !== '') {
            $lines[] = $line;
            $line = $word;

            continue;
        }
        $line = $try;
    }
    if ($line !== '') {
        $lines[] = $line;
    }

    return $lines;
}

/**
 * @param array{title:string, kicker:string, footer:string, out:string} $card
 */
function draw(array $card): void
{
    $serif = ROOT.'/assets/fonts/InstrumentSerif-Regular.ttf';
    $mono = ROOT.'/assets/fonts/IBMPlexMono-Medium.ttf';

    $im = imagecreatetruecolor(W, H);
    imageantialias($im, true);
    $paper = imagecolorallocate($im, ...rgb('#faf7f1'));
    $ink = imagecolorallocate($im, ...rgb('#14181a'));
    $muted = imagecolorallocate($im, ...rgb('#6b6558'));
    $accent = imagecolorallocate($im, ...rgb('#0d6b63'));
    $rule = imagecolorallocate($im, ...rgb('#e2ddd1'));
    imagefilledrectangle($im, 0, 0, W, H, $paper);

    // The kicker, tracked like the site's own small caps.
    tracked($im, $accent, $mono, 15.5, PAD, 104, mb_strtoupper($card['kicker']), 3.4);

    // The title, in the one weight the serif has. A heading that does not shout
    // sits better on a cream ground than a bold one — the stylesheet says so,
    // and a card is not the place to contradict it.
    $size = 54.0;
    $lines = wrap($card['title'], $serif, $size, W - (2 * PAD));
    while (\count($lines) > 4 && $size > 34) {
        $size -= 3;
        $lines = wrap($card['title'], $serif, $size, W - (2 * PAD));
    }
    // The block is centred in the band between the kicker and the foot rather
    // than hung from the top: a two-line title and a four-line one have to look
    // composed, and the first draft left 160px of dead paper above the foot.
    $lines = \array_slice($lines, 0, 4);
    $leading = (int) round($size * 1.28);
    $top = 168;
    $bottom = H - 128 - 52;
    $block = (\count($lines) * $leading) + 34;
    $y = $top + (int) round((($bottom - $top) - $block) / 2) + $leading;
    foreach ($lines as $line) {
        imagettftext($im, $size, 0, PAD, $y, $ink, $serif, $line);
        $y += $leading;
    }

    // One accent mark, once: a short rule under the title.
    imagefilledrectangle($im, PAD, $y - $leading + 30, PAD + 78, $y - $leading + 33, $accent);

    // The foot: a hairline, what the machine knows on the left, the house on
    // the right.
    imagefilledrectangle($im, PAD, H - 128, W - PAD, H - 127, $rule);
    tracked($im, $muted, $mono, 14.5, PAD, H - 84, mb_strtoupper($card['footer']), 2.6);
    $mark = 'BLACKMESA LABS';
    $box = imagettfbbox(14.5, 0, $mono, $mark);
    $markWidth = (int) round(($box[2] - $box[0]) + (mb_strlen($mark) * 2.6));
    tracked($im, $ink, $mono, 14.5, W - PAD - $markWidth, H - 84, $mark, 2.6);

    imagepng($im, $card['out'], 9);
    imagedestroy($im);
}
