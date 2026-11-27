---
title: "What your machine sees"
standfirst: "When you open a site over https, it proves who it is with a key. Stellar draws that key so that you notice the day it changes. One gap remained: our site showed the key our server receives, not the one you receive. Here is how we closed it, explained step by step, with what we broke on the way."
key: ce-que-votre-machine-voit
date: 2026-11-26
slug: what-your-machine-sees
---

This piece follows ["Every key has a sky"](/en/every-key-has-a-sky/). It can be read without it: we take up each notion as we go.

## First, which key are we talking about?

When your browser shows a padlock, this is what happened: the site presented it with a **certificate**, a kind of digital identity card. In that certificate is a **public key**, a very large number that only the site can use the other way round, thanks to a private key it keeps to itself. As long as the site proves it holds the matching private key, your browser knows it is talking to that site, and everything that travels is encrypted for it alone.

That public key is too long to be read. So a summary of it is computed, the **fingerprint**: a string of some fifty characters, always the same for the same key, and different as soon as a single bit of the key changes. Two identical fingerprints mean the same key.

Nobody compares fifty characters by eye. That is where [Stellar](https://stellar.mesa.black) starts: it turns the fingerprint into a constellation with a name. Same key, same sky. Different key, an unrelated sky. A sky is not read, it is recognised.

## The gap we had left

The danger we are trying to see is called an **interception**. Somebody stands between you and the site, on a wifi network for instance, and pretends to be the site. They present *their* key instead of the site's, decrypt what you send, then pass it on to the real site as if nothing had happened.

An interception is therefore two keys for one site: the real one, which the site serves to the rest of the world, and the false one, which is served to you.

Yet our site only looked from one place. When you ask it for the sky of `example.org`, it is *our server* that fetches the key of `example.org`, from our data centre. If somebody intercepts you, in your café, our server sees none of it: it receives the real key and draws you a reassuring sky. The previous piece said so in its list of limits. It was the most awkward one.

## Looking from two places

To see an interception, the key has to be read **where you are**, then compared with the one seen from elsewhere.

A website cannot do the first half: a page is not allowed to read the certificate of the connection that brought it. A browser **extension**, the small program one adds to a browser, can. But in one browser only: Firefox gives the certificate of each page to its extensions, Chrome and Safari do not.

So we wrote an extension for Firefox. It does three things.

**It draws the sky of the page**, from the key your own machine received. The computation happens in your browser, without asking anybody anything.

**It remembers.** It keeps the sky each site showed at your last visit, and warns you if it has changed. A change is not necessarily an attack: a site renews its certificate every two or three months, often with a new key. But it is a reason to look.

**On a click, it asks our server** which key it receives from the same site. If the two keys are identical, what you see matches what the rest of the world sees. If they differ, there is something to understand.

Nothing leaves your machine before that click. When you click, two things go: the name of the site, and the fingerprint of its key. The fingerprint is public by nature, anybody can read it by visiting the site. The name of the site tells our server where you are; the extension declares so when it is installed, and that is why it never does it without you.

A word about the kitchen. For the extension to draw exactly the same sky as the site, the computation had to be written a third time. Stellar is written in Go. Our inventory tool, [Sablier](https://github.com/mesa-black/sablier), is written in PHP and draws the sky of its own signing keys on its reports: that was the second writing. The extension lives in a browser, hence in JavaScript. Three programs in three languages that must land on the same drawing, to the stroke. The repository holds thirty-two reference skies, and each writing is refused if it draws a single one of them differently.

## Comparing a key, by hand

The question the extension asks, you can ask without it. Imagine a colleague dictates to you over the phone the fingerprint of their server's key, or hands it to you on a business card. You want to know whether the site in front of you presents that very key.

Under the sky of a site, Stellar now accepts the key you were given, in any common form, and answers yes or no: it is the key this site serves, or it is not.

On the screen, six signs spin like a roulette and stop one after the other, green when they match, red when they do not. It is pleasant to watch, and what it is must be said: a **picture of the answer**, not the answer. The answer comes from the two fingerprints, compared whole by the server.

The difference is measured in **bits**, the unit of what has to be guessed in order to cheat. The six signs carry 36: there are about 54 billion combinations, which sounds enormous and is within reach of somebody determined, with rented hardware. A fingerprint carries 256: a number of possibilities no machine will ever run through. Two different keys can therefore have the same six signs. In that case the page shows six green signs, refuses all the same, and explains why.

A last safeguard: if you paste a **private** key by mistake, the one that must never leave its server, the page refuses it before sending it and empties the field.

## Six signs and a chart

Those six signs we call the **gate**. Each key draws six, in a precise order, from a catalogue of sixty-four drawings shared by everybody. It is a second way to name a key: less precise than a fingerprint, but six drawings are dictated and remembered better than fifty characters.

### Why so few bits?

One may be surprised: 36 bits for the gate, 33 for the name of a sky, when the fingerprint carries 256. It is not a technical limit, it is a choice, and it deserves an explanation.

**Where the number comes from.** The first sign is chosen among 64, the second among the 63 that remain, and so on to the sixth. That makes 64 × 63 × 62 × 61 × 60 × 59, about 54 billion possible gates. It takes 36 bits to count that far.

**Why not more.** Each added bit is paid for in comfort. Twelve signs instead of six would give 70 bits, but nobody dictates or remembers twelve drawings any more. At the other end, the whole fingerprint is unbeatable, and it is precisely the one nobody reads. Between the two, one has to choose what a human can actually handle. Six signs is what seemed reasonable to us to dictate and to compare; it is a judgement, not a measurement.

**What it imposes.** A tool that carries only 36 bits must never decide alone. The gate and the name serve to *notice* a change and to *name* a key in a conversation: "on my side the site is called Jilajix Figensis, and on yours?". They do not serve to *accept* a key. That is why the comparison described above is made on whole fingerprints, and why the signs are only its picture.

We could go higher: eight signs drawn from a catalogue of 256 would give 64 bits, out of reach of an ordinary attacker. We did not, because a catalogue of 256 drawings nobody can tell apart would be worth no more than a fingerprint nobody reads. And we have not yet measured what people really tell apart.

We also drew a chart in three dimensions from them: the sixty-four signs set on a sphere, the six of the gate joined two by two, and the key placed at the point nearest the three lines. Two sites can be put on it to see the distance between them. The chart is pretty and carries no more information than the six signs. It says so underneath.

## What we broke

**We published a game.** The first version invited you to "dial the gate" by clicking the signs one by one, with hints when you were wrong. It was fun and beside the point: a site about security has no business offering a riddle whose solution is displayed just above. We removed it the next day, in favour of the comparison described above, which keeps the animation and answers a real question.

**We brought the site down.** Stellar deliberately runs in very little memory, 64 MB, a fraction of what a single browser tab uses. The day we added the download of a sky as a picture, drawing the first one took 70 MB. The system stopped the program, twice in a row. Two minutes of downtime, caused by our own test. Since then memory is measured before going live, and an automatic test fails if a drawing exceeds its share.

**We locked our own browser.** A site can tell the browser: "always come back over https, never in the clear". It is a good protection, and the browser remembers it for a year. We turned it on, including, by mistake, on the working copy that runs in the clear on the developer's machine. The browser obeyed: it demanded https from a program that spoke none, and showed nothing any more. The site now gives that instruction only to those who reach it under its real address.

**A load test found what nobody had seen.** A load test sends many requests at the same time to see what gives way. Three thousand requests, fifty at a time: every answer was right, but one in a hundred took ten seconds. When several visitors asked for the same picture at the same instant, each waited their turn, then drew it again instead of taking the one the first had just produced. After the fix, the same answer comes in under half a second.

**A sentence displayed its own accident.** For a few hours, the paragraph that explains the comparison showed every visitor a piece of code in place of the name of the site. No check read that paragraph. A test now opens every kind of page, in the three languages, and refuses the slightest trace of that kind.

**No test opened the site in a browser.** At each change, automatic checks verify that nothing is broken. They read the code of the site, not what a browser makes of it: the animation, the memory of visits, the refusal of private keys could have broken without anything lighting up. The checks now open the site in a real Firefox, without a window, and act on it as a visitor would: twelve verifications at each change.

## What it catches

After a list of mishaps, it is time to say what all this is for. The comparison between what your machine receives and what our server receives catches **any interception close to you**. Those are, by far, the most common:

- **A public wifi or a compromised home router.** Whoever holds the network stands between you and the site. Your machine receives their key; our server, which does not go through that network, receives the real one.
- **A corporate proxy.** Many organisations decrypt their employees' https to inspect it, then encrypt it again with their own key. It is legal and often announced, seldom understood. The extension shows it unambiguously: the sky you see is not the site's.
- **An antivirus or parental control** that does the same thing on your own machine.
- **Malware** that has installed its own certificate authority, so that the padlock stays green while it reads everything.

In these four cases the browser shows its usual padlock and nothing looks wrong. That is precisely where a second point of view is useful: two different skies for one site, visible in one click.

To this is added the memory of the extension. Even without asking our server anything, it tells you that a site no longer presents yesterday's key. It is the principle that has protected SSH connections for thirty years: trust the first meeting, and worry about the change.

## What it does not prove

These limits are real. They do not cancel what comes before, they draw its edge.

- **A difference is not always an interception.** This is the most awkward limit in practice. A very large site spreads its visitors over many servers, each of which may have its own certificate and key. On those sites, two different skies may be perfectly normal. On a site of ordinary size, which has one key, it says a great deal more. In both cases a difference is a reason to look closely, not a verdict. To settle the doubt, Stellar then offers to look for the key you see in the public logs where every certificate issued by an authority is written. If it is there for this name, it is one of the site's keys. If it is not, it is serious: the certificate of an interceptor or of a corporate proxy is never written there. That search sends the name of the site to a third-party service, so it is done only on request.
- **An interceptor placed close to the site escapes the comparison.** If they stand on everybody's path, at the hosting company for instance, your machine and our server receive the same false key. It is rare, it takes other means than holding a wifi, and it is what a key announced and signed by the owner in their DNS deals with, the subject of the previous piece. The two mechanisms complete each other: one looks close to you, the other close to the site.
- **Our server learns the name of the site** when you click. That is the price of the comparison, and the reason it never happens without you.
- **One browser only.** As long as the others do not give the certificate to their extensions, there is nothing to adapt.
- **The extension is not in Mozilla's catalogue yet.** It is installed from the repository.
- **The signs do not replace the fingerprint**, for the reasons given above.

## Sources

- **Ours**: [Stellar](https://stellar.mesa.black), [its code and the extension](https://github.com/mesa-black/stellar), [Sablier](https://github.com/mesa-black/sablier), and the previous piece, ["Every key has a sky"](/en/every-key-has-a-sky/).
