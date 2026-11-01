---
title: "You cannot secure Luhn. That is why your card has a CVV."
standfirst: "The Luhn formula has been explained a thousand times. What gets explained less is that it protects against nothing, that making it \"more secure\" is a category error, and that the payment industry understood this back in the 1990s. We also checked what our own tool sees when code uses it as a lock: nothing. That is fixed, in part, and here is what remains."
key: on-ne-peut-pas-securiser-luhn
date: 2026-11-05
slug: you-cannot-secure-luhn
---

The last digit of a card number is not part of the account number. It is a check digit, computed from the other fifteen with a [formula](https://en.wikipedia.org/wiki/Luhn_algorithm) that Hans Peter Luhn, an engineer at IBM, patented in 1960. It is in card numbers, in phone IMEIs, and in every French company identifier (SIREN and SIRET).

It fits in three lines. Starting from the right, double every second digit; when the double is over 9, subtract 9; add everything up. The number is valid if the sum is a multiple of 10. `79927398713` passes, `79927398712` does not.

This post starts from an idea that comes up regularly, and that we had too: since everybody knows the formula, why not harden it? Change its "crypto mode", put a key in it, make it into something secure. The short answer is that you cannot, and the reason is more useful than the formula itself.

## What Luhn actually does

Luhn does not protect a number. It protects against a typing mistake: a human copying sixteen digits from a card, over the phone or on a keyboard. At that job it is very good, and we checked rather than copied the claim:

- it catches **every single-digit error**;
- it catches **every swap of two adjacent digits, except `09` ↔ `90`**;
- it misses a few "twin errors", where two identical digits are replaced by two other identical ones: `22` ↔ `55`, `33` ↔ `66`, `44` ↔ `77`.

That is all it is asked to do. The formula contains no secret: anybody can compute it, and that is on purpose, since it is the payment form that has to be able to say "you must have mistyped" before sending anything.

For an adversary, the consequence is immediate. A random number passes the check **one time in ten** (over a hundred thousand draws, we counted 10.2%). And any fifteen chosen digits always have a sixteenth that makes them valid: you just do the arithmetic. A protection you can compute yourself protects against nothing.

## Why it cannot be hardened

Suppose we replace Luhn's arithmetic with a function that takes a secret key. The check digit becomes impossible to compute without the key: wish granted. But what we have built has a name: it is a **[message authentication code](https://en.wikipedia.org/wiki/Message_authentication_code)**, a MAC. And a MAC is judged by its length.

One decimal digit is 3.3 bits. An adversary who does not know the key guesses the right digit one time in ten, exactly as before. We have added a key to manage, rotate and protect, and the forgery probability has not moved one bit.

To reach the security expected of a modern MAC, 128 bits, it would take **39 check digits**. A card number does not have a single one to spare: the format is fixed by ISO/IEC 7812, and terminals and forms all over the world expect it as it is. An identifier's security budget is counted in digits, and this one's is zero.

So the problem is not that Luhn is "weak". It does something else entirely, and does it perfectly. Protecting against an accident and protecting against an adversary are two different jobs, and the first is not a cut-price version of the second.

## What the industry did instead

The payment sector asked itself the same question, and answered by leaving Luhn alone and putting the security next to it.

**The [CVV](https://en.wikipedia.org/wiki/Card_security_code) is exactly the "Luhn with a key" we were looking for.** The three digits on the back of the card are computed by the issuing bank, with a pair of secret keys ([3DES](https://en.wikipedia.org/wiki/Triple_DES), inside a hardware security module), over the card number, the expiry date and a service code. Without the key they cannot be computed. It is a MAC.

And it has exactly the flaw described above: three digits, barely 10 bits. One in a thousand. What makes it usable is not the cryptography, it is everything around it. The bank blocks the card after a few wrong attempts, and [PCI DSS](https://en.wikipedia.org/wiki/Payment_Card_Industry_Data_Security_Standard) forbids storing the CVV after authorisation. When those conditions fail, three digits do not hold: in 2016, researchers at Newcastle University showed that by spreading guesses over hundreds of merchant sites, which do not talk to one another, a card's CVV could be found in a matter of seconds.

The lesson is the same as for Luhn, one step further: **a MAC that is too short is only secure as long as somebody counts the attempts**.

The industry understood this well enough that it eventually turned the other dial. Since the mid-2010s, some banks have offered cards with a **dynamic CVV**: a small screen on the back shows a code that changes at regular intervals, and banking apps do the same for virtual cards. The code still has three digits. Nobody tried to make it longer, since the format does not allow it. Its lifetime was made shorter instead. A CVV guessed across a hundred merchant sites is worthless if it has changed before the attack is over, and a CVV stolen along with the rest of the card expires on its own. It is the principle behind the [one-time codes](https://en.wikipedia.org/wiki/One-time_password) in our authenticator apps: when a secret cannot be made longer, make it die quickly.

**[Tokenisation](https://en.wikipedia.org/wiki/Tokenization_%28data_security%29) is the other answer.** When Apple Pay or Google Pay registers a card, the phone does not receive the real number. It receives a token issued by the network, shaped like a card number, Luhn included, so that terminals and forms accept it without changing anything. The token is worthless outside the device and the context it was issued for. [Format-preserving encryption](https://en.wikipedia.org/wiki/Format-preserving_encryption) (FF1, standardised by NIST in SP 800-38G) does a related job: it encrypts a sixteen-digit number into another sixteen-digit number.

In both cases Luhn stays what it is: a typing check laid over a number, whether that number is real, a token or encrypted. The security lives elsewhere, in a key, a hardware module and an attempt counter.

A word on quantum computing, since it is our usual subject: none of this depends on it. A MAC rests on a shared key, which a quantum computer weakens only marginally. A CVV does not need a quantum computer to be guessed, it needs a merchant site that does not count attempts.

## What our tool sees

[Sablier](https://github.com/mesa-black/sablier) reads a repository and lists all the cryptography it finds there. So the natural question was: what does it say about code that uses a typing check as a lock? We wrote a four-file project to find out, and ran the published version, 0.11.1, on it without changing anything.

The four files:

- a voucher accepted on the strength of its Luhn check digit alone, then credited with €50;
- a password-reset link "signed" with `crc32()`, and an authentication token checked with `hash('crc32b', …)`;
- the same link, signed properly with `hash_hmac('sha256', …)` and a secret key, as a control;
- card numbers stored with `openssl_encrypt(…, 'des-ede3-cbc', …)`.

The report:

```
  . — 4 files read, 3 findings, 0.0 s
  declaration: none (default lifetimes)

    BROKEN TODAY             1
    CLEAR                    1
    PROBABLY NOT SECURITY    1
```

The 3DES is found and filed as broken, the [HMAC](https://en.wikipedia.org/wiki/HMAC) is found and filed as clear. The voucher, the CRC-signed link and the CRC-checked token **appear nowhere**. Yet they are the only three places in the project where a stranger can get something that does not belong to them.

The reasons were precise, and they were all in the code:

- **A hand-written Luhn check has no signature.** It is a loop, a doubling and a modulo 10. There is no library call to recognise, and we had never tried.
- **`crc32()` was looked for by no rule.** It is a PHP function, easy to spot, and nobody had thought of it.
- **`hash('crc32b', …)` was seen, then dropped.** The rule that reads `hash()` found the call, looked `crc32b` up in its catalogue, did not find it, and applied a rule written precisely against false positives: *an algorithm we do not know is not ours to judge.* Yet the line contains `$authToken`, one of the words that, elsewhere in the same file, turn a finding back to red.
- **The word "checksum" silenced the tool.** It is still in the list of hints that mark an identifier rather than a security control. An `md5()` over a reset token, in a function called `checksum`, therefore comes out as "probably not security". In this precise case the conclusion holds up, since MD5 collisions are useless against the digest of a random token. But the reasoning is wrong: the tool filed it with the cache keys because it read the function's name, not because it understood what the function protects.

There is worse than silence. Every Sablier report ends with a section called "What this report did not look at", because an inventory that hides its blind spots manufactures false assurance. That section covered managed services, HSMs, images, YAML. **It did not mention checksums.** The reader of that report had every reason to believe their reset links had been looked at.

This is not a one-off slip, it is the consequence of a choice we still stand by. The lists that silence the tool were built from a measurement: twenty public repositories, eighty-nine findings filed as "broken", eighty-two of which were cache keys, filenames or identifiers. Without those lists, the seven real findings drowned. With them, across thirty-one repositories, only three of twenty-one reds are wrong. But a list that silences the tool on a word needs the opposite rule, the one that notices when that word names exactly the thing being protected, and for "checksum" that rule did not exist.

## What the tool says now

The missing finding was not "CRC32 is broken". [CRC32](https://en.wikipedia.org/wiki/Cyclic_redundancy_check) is not broken; it does very well what it exists for, checking that a file was not damaged on the way. That finding would be false, and that kind of error teaches the reader to stop believing the red ones. The right finding is about the **use**, and it is the one Sablier now prints:

> **BROKEN TODAY** — `src/ResetLink.php:8`
> A checksum protects against an accident, not against somebody: it has no key, and anyone can recompute it. The deadline was yesterday.
> *Replacement: HMAC-SHA-256 with a secret key, compared with `hash_equals()`*

On the same four-file project, the report goes from three findings to six:

```
  . — 4 files read, 6 findings, 0.0 s
  declaration: none (default lifetimes)

    BROKEN TODAY             4
    CLEAR                    1
    PROBABLY NOT SECURITY    1
```

The three checksums on the reset link and the token are red, and so is the 3DES. The link signed with a key stays clear.

The rule is deliberately narrow. A `crc32()` is reported only when it sits next to something a stranger would want to forge: a token, a reset link, a password, a secret, a signature, a voucher, read on the line, in the function's name and in the file's name. Everywhere else it stays silent: verifying a download, spreading sessions across servers, computing an ETag is exactly what a checksum is for. The test that comes with the fix contains those three uses, and it fails if any of them turns red. Without it, we would have replaced a silence with noise.

What is not fixed is Luhn itself. The voucher accepted on its check digit still does not appear: a loop, a doubling and a modulo cannot be told apart from ordinary arithmetic, and recognising one by its shape is a project of its own. Until then, the report says so, in its blind spots section, in so many words:

> Checksums (CRC32, Adler-32) are reported only beside a token, a link or a secret. A Luhn check digit or a modulo written by hand never is: nothing tells it apart from ordinary arithmetic, and code that accepts a number on the strength of its check digit does not appear here.

Luhn does not need to be secured. It needs people to stop asking it to be, and a tool that claims to take inventory to say so when it cannot see somebody doing it.
