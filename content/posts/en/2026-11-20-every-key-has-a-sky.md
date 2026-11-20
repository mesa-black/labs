---
title: "Every key has a sky"
standfirst: "The starting idea was to invent a cryptography based on constellations. It does not hold, and we explain why. What was left of it does: Stellar draws a site's public key as a constellation with a name, so that a human notices the day it changes. Then we had that sky announced by the DNS of our own sites, signed, and followed at every certificate renewal. Here is what that proves, and above all what it does not."
key: chaque-cle-a-son-ciel
date: 2026-11-20
slug: every-key-has-a-sky
---

It all started with one sentence: *what if we created a new model of cryptography, like RSA, but based on constellations? It will take light-years before a constellation disappears from our sight.*

It is a dreamer's idea, and we stand by that. People have found their way by the stars forever: sailors to hold a course, children to find the Great Bear again. Wanting to entrust to that sky the most fragile thing we have, our secrets, is not absurd. It is the kind of idea you have looking up, not reading a standard, and projects that start that way are not the worst ones.

The image is a fine one. It does not make an encryption system, and it is better to say why before telling what we built instead.

## Why stars encrypt nothing

A public-key system rests on a problem anybody can state and nobody knows how to solve backwards. For [RSA](https://en.wikipedia.org/wiki/RSA_cryptosystem), it is finding two large primes from their product. Security comes from there: from a computation that is easy one way and out of reach the other.

The sky is the opposite of a secret. The position of the stars is the most public data there is, measured and published for centuries. Nothing can be hidden in it, and no hard problem lives there. That a constellation lasts millions of years changes nothing: how long an object lasts has never protected a key.

So we set aside the idea of a "stellar cryptography". Inventing your own cipher is, besides, the first thing this trade teaches you not to do.

But the intuition held something else, and that part was right: **a human recognises a sky. A human does not recognise a string of characters.**

## The problem nobody looks at

A website proves who it is with a public key. That key is summed up in a fingerprint, for instance:

```
SHA256:9f3ntWkWWH7QVXvTp7oFXjDeN34LcvBOGX22U4Qu2ps
```

Nobody compares that. Nobody remembers it from one visit to the next. The day a site's key changes, because a certificate was renewed or because somebody else is answering in its place, nothing tells a human eye.

Drawing a fingerprint is not a new idea, and we do not claim it as ours. OpenSSH has been able to show a small drawing of a server's key since 2008 (the `VisualHostKey` option, analysed in ["The drunken bishop"](http://www.dirk-loss.de/sshvis/drunken_bishop.pdf)). The geometric avatars some sites use start from the same principle. What those drawings lack is what lets people talk about them: a name.

## What Stellar does

[Stellar](https://stellar.mesa.black) takes the fingerprint of a public key and derives from it, always the same way, a constellation:

- seven to twelve main stars, each with a position, a brightness and a colour;
- lines joining them into a single figure;
- a background of fainter stars;
- and a name, for instance *Zijizia Vudensis*.

The same key always gives the same sky. A different key, even by a single bit, gives another one, with no resemblance. Nothing in the computation is secret: the fingerprint goes through [SHAKE256](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf), a standard hash function, and every star is drawn from the result. The algorithm is written down in the [repository](https://github.com/mesa-black/stellar), with thirty-two reference examples for anyone who wants to rewrite it in another language. We did so once ourselves, in PHP, for [Sablier](https://github.com/mesa-black/sablier).

Stellar encrypts nothing and replaces nothing. It is a way of **looking at** a fingerprint.

### Invented names, and why

The names are fictional. None is the name of a real constellation, and the drawings match none either.

Real names would not do. There are eighty-eight official constellations: unrelated keys would share a name all the time, and making a key called *Orion* like yours would take a few dozen tries. The invented scheme gives about 8.4 billion names. They are built to sound like the Latin of astronomers, because the point is to be able to say them aloud: "on my side, your site is called Zijizia Vudensis. And on yours?"

## The same sky wherever the key appears

We invented no fingerprint format. Stellar draws the ones that already exist:

- for an SSH key, the fingerprint `ssh-keygen -l` prints;
- for a website, the SHA-256 of its certificate's public key.

The consequence is practical: the sky the website shows, the one the command line draws and the one a colleague gets on their machine are the same, because they start from the same thirty-two bytes.

```
$ stellar -host stellar.mesa.black
Name:        Zijizia Vudensis
Fingerprint: SHA256:9f3ntWkWWH7QVXvTp7oFXjDeN34LcvBOGX22U4Qu2ps
Key:         stellar.mesa.black:443 (X.509 certificate)
Certificate: ECDSA P-256, until 2027-02-18, Let's Encrypt YE2
Connection:  TLS 1.3, X25519MLKEM768 (post-quantum hybrid)
```

In the terminal, the constellation is drawn above those lines. Sablier's signed reports carry the sky of their signing key too, under the seal. It is not the same as the sky of the site that publishes them, and that is normal: they are two different keys, one signs a report, the other a certificate. We were asked the question on the first day, and the report has since printed the full fingerprint beside the drawing, so that one can check which key is being looked at.

## "A sky that changes every two months is useless"

This is the serious objection, and it kept us busy longer than the drawing did.

The website remembers, in your browser and nowhere else, the sky each name showed on your last visit. If the sky has changed, it says so. But our certificates are renewed every two months, with a new key each time: we keep no key longer than a certificate lives. So the sky of our sites changes six times a year, legitimately. A signal that goes off six times a year for nothing is a signal people learn to ignore.

Something other than the visitor's memory was needed: **the site's owner saying which sky to expect.**

## The sky the owner announces

The mechanism has existed since 2012 and we had nothing to invent. A domain can publish in its DNS a `TLSA` record ([DANE, RFC 6698](https://www.rfc-editor.org/rfc/rfc6698)) saying which key its site must present. The recommended form, `3 1 1`, holds the SHA-256 of the certificate's public key.

That is exactly the fingerprint Stellar draws a sky from. "The sky announced by the owner" is therefore not a format of ours: it is a standard record, read as a sky. Stellar compares what the site shows with what its DNS announces, and says whether it is the same key, another one, or whether the domain announces nothing.

It still had to be done at home. Three pieces, put in place on 20 November 2026:

**The zone is signed.** Without [DNSSEC](https://www.rfc-editor.org/rfc/rfc4033), a `TLSA` record is worth no more than the DNS that carries it, which is not much. `mesa.black` is signed, and resolvers that validate mark its answers as authenticated.

**The announcement follows the key.** A record written by hand would be wrong at the very next renewal. So a task runs every five minutes in our cluster: it reads the key each site serves, as a visitor would, and corrects the record when it differs. It never reads the private keys. This is the `stellar announce` command, published with the rest.

**Only our account can obtain a certificate.** Two [`CAA`](https://www.rfc-editor.org/rfc/rfc8659) records allow a single authority, for a single account and a single validation method ([RFC 8657](https://www.rfc-editor.org/rfc/rfc8657)), and forbid wildcard certificates.

We did not wait for the next renewal to find out whether the whole thing held. We caused one, on Stellar's own site. The certificate was issued under the new `CAA` rule, the site's sky went from *Kamubum Haparis* to *Zijizia Vudensis*, and about three minutes later the DNS announced the new key.

## What it does not prove

This is half the subject, as usual.

- **The name alone proves nothing.** It carries about 33 bits. Someone deliberately looking for a key with the same name as yours finds one in a few minutes of computing. The name is for talking about a sky, not for accepting it.
- **Neither does the drawing, against someone determined.** An eye compares fewer bits than the fingerprint holds. Whoever can make many keys can search for one whose sky resembles yours. The drawing is for noticing a change; when it matters, compare the full fingerprint.
- **We ran no study.** Nobody has measured how well people tell two of these constellations apart. Until that is done, any claim about their legibility would be an opinion.
- **The website sees the key from our server, not from where you are.** Someone intercepting your own connection is not visible from there. To know what your machine receives, run the command on your side.
- **Stellar does not validate DNSSEC itself.** It asks the machine's resolver whether it did, and repeats the answer. "Signed" means: that resolver checked. On a network whose resolver does not validate, Stellar says it does not know, and it is right.
- **No browser enforces DANE.** The announcement blocks nobody: it lets whoever wants to check do so. That is also why our delay is acceptable: after a renewal, the DNS announces the previous key for ten minutes at most.
- **The DNS is still a third party.** DNSSEC moves the trust to the domain's registry and to the root. It is a second road, independent of the certificate authorities, which is the whole point. It is not the absence of trust.

## Checking it without us

Nothing above needs Stellar. The fingerprint of the key a site presents:

```
$ openssl s_client -connect stellar.mesa.black:443 -servername stellar.mesa.black </dev/null 2>/dev/null \
    | openssl x509 -pubkey -noout \
    | openssl pkey -pubin -outform der \
    | openssl dgst -sha256
f5fde7b56916587ed0557bd3a7ba055e30de377e0b72f04e197db653842eda9b
```

And what its owner announces:

```
$ dig +short TLSA _443._tcp.stellar.mesa.black
3 1 1 F5FDE7B56916587ED0557BD3A7BA055E30DE377E0B72F04E197DB653 842EDA9B
```

The two values are the same. Taken on 20 November 2026; they will have changed at the next renewal, together if everything works. With `dig +dnssec` against a resolver that validates, the `ad` flag also says the answer is signed.

Stellar adds one thing to those two commands: a drawing and a name, for the person who will never run them.

## Trying it

- **The website**: [stellar.mesa.black](https://stellar.mesa.black). Type a domain name, a public key or a fingerprint.
- **The command line**: one binary per platform on the [releases page](https://github.com/mesa-black/stellar/releases), with no dependency. `stellar -host example.com`, `stellar ~/.ssh/id_ed25519.pub`.
- **At home**: the website is the same binary (`stellar serve`), in a container image that holds nothing else.

The code is under the MIT licence.

## Good practice

- **Compare the fingerprint when it matters.** The sky makes you notice a change, the fingerprint proves it.
- **Never accept a key on its name.** Say the name, look at the drawing, check the fingerprint.
- **Announce your key, and make the announcement follow.** A `TLSA` that is not updated at each renewal becomes wrong, and a wrong record is worse than none.
- **Sign the zone before writing anything important in it.** Without DNSSEC, the announcement is worth what the network between you and your resolver is worth.
- **Watch from outside.** Our follow-up task can fail in silence. A second one, every day, checks what a stranger would see, and writes when it is wrong.

## Watch out for

- A `CAA` that is too strict only shows at the next issuance. After writing it, renew a certificate on purpose.
- Changing name servers without first removing the signature from the registry makes a domain unreachable.
- An API token that edits your DNS is a key to your domain. Ours is limited to one zone and it expires.
- Looking a name up in the public certificate logs sends that name to a third party. The website does it only when you ask, and says so.
- A drawing reassures quickly. That is its quality and its danger: a familiar sky is not a verification.

## References

- **DANE**: [RFC 6698](https://www.rfc-editor.org/rfc/rfc6698) and the operational guidance of [RFC 7671](https://www.rfc-editor.org/rfc/rfc7671).
- **DNSSEC**: [RFC 4033](https://www.rfc-editor.org/rfc/rfc4033).
- **CAA**: [RFC 8659](https://www.rfc-editor.org/rfc/rfc8659), and [RFC 8657](https://www.rfc-editor.org/rfc/rfc8657) for the account and the validation method.
- **SHAKE256**: [FIPS 202](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf).
- **Key drawings in OpenSSH**: ["The drunken bishop"](http://www.dirk-loss.de/sshvis/drunken_bishop.pdf), Loss, Limmer and von Gernler, 2009.
- **Our post-quantum Observatory** (in French): [RSA](https://observatoire.mesa.black/comprendre#g-rsa), [the hash function](https://observatoire.mesa.black/comprendre#g-hachage).
- **Ours**: [Stellar](https://stellar.mesa.black) and [its code](https://github.com/mesa-black/stellar), [Sablier](https://github.com/mesa-black/sablier), and [this site's inventory](/audit/en/report.html).
