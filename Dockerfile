# syntax=docker/dockerfile:1
#
# The blog as a container image: every dated version of the site, built once,
# served by Caddy. Which version is live is decided at run time by
# container/labs-switch (a sidecar in Kubernetes), exactly as the server's timer
# does today with a symlink.
#
#   podman build --build-arg SITE_DATE=$(TZ=Europe/Paris date -v-7H +%F) -t labs .
#
# Two stages. The build stage runs on the BUILD machine's architecture
# ($BUILDPLATFORM): its output is HTML and PNG, the same whatever CPU produced
# it. Only the final stage exists per target architecture, and it only copies
# files — so a multi-arch image (amd64 for the server, arm64 for a laptop) never
# runs PHP under emulation.

# ------------------------------------------------------------------ php
# The PHP the site is built with — also what the Makefile runs on a
# workstation without PHP (`podman build --target php`), so that a local
# build and the image's cannot disagree again (the word count once did).
FROM --platform=$BUILDPLATFORM php:8.4-cli AS php

# gd with FreeType draws the sharing cards; without it every piece ships with no
# image. unzip lets Composer install from dist archives instead of cloning.
RUN apt-get update \
 && apt-get install -y --no-install-recommends libfreetype-dev libpng-dev unzip \
 && docker-php-ext-configure gd --with-freetype \
 && docker-php-ext-install -j"$(nproc)" gd \
 && rm -rf /var/lib/apt/lists/*
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# The publication calendar is the author's: dates are compared in Paris, as
# release.sh does on the server.
RUN echo 'date.timezone = Europe/Paris' > /usr/local/etc/php/conf.d/timezone.ini

# ------------------------------------------------------------------ build
FROM php AS build
WORKDIR /src
# Dependencies first, in their own layer: a new post does not reinstall them.
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist --no-autoloader
COPY . .
RUN composer dump-autoload --no-dev --classmap-authoritative

# The publication day the image is built for (Paris, before 07:00 it is still
# yesterday — see container/labs-switch), passed in rather than read from the clock:
# a build cache keys layers on their instructions and inputs, never on the date,
# so a `RUN date` layer cached yesterday would silently build yesterday's site.
# A different SITE_DATE is a different input, so it invalidates the cache.
ARG SITE_DATE
ARG SITE_URL=https://mesa.black
# One complete version per publication date still ahead, plus the publication
# day and the calendar day. Both of the last two, because before 07:00 they
# differ: the switch serves the publication day (yesterday), and a piece dated
# today is not "ahead" for --release-dates, so its version must be built too or
# it would never come out. Release dates are filtered to date-shaped lines: a
# stray PHP warning once became nine release directories.
RUN test -n "$SITE_DATE" || { echo "✗ --build-arg SITE_DATE=YYYY-MM-DD is required"; exit 1; } \
 && for d in $( { php bin/build.php --release-dates; php -r 'echo date("Y-m-d"), "\n";'; echo "$SITE_DATE"; } \
               | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' | sort -u ); do \
        SITE_URL="$SITE_URL" php bin/build.php --as-of="$d" >/dev/null \
     && mkdir -p /out/releases \
     && rm -rf "/out/releases/$d" && mv public "/out/releases/$d" \
     && printf '  version %s — %s pages\n' "$d" "$(find "/out/releases/$d" -name '*.html' | wc -l)"; \
    done

# ------------------------------------------------------------------ serve
FROM caddy:2.11.7-alpine

# The official image gives the binary a file capability (cap_net_bind_service)
# so that it can bind port 80 without root. This image listens on 8080, and the
# pod drops every capability and forbids gaining any: the kernel then refuses to
# exec a binary that asks for one ("exec /usr/bin/caddy: operation not
# permitted"). Removed rather than granted back: least privilege.
RUN setcap -r /usr/bin/caddy

COPY --from=build /out/releases /srv/releases
COPY container/Caddyfile /etc/caddy/Caddyfile
COPY container/labs-switch /usr/local/bin/labs-switch

# The calendar is Paris's. This image has no tzdata, so `Europe/Paris` would be
# silently UTC and a piece dated today would wait until 02:00. A POSIX TZ string
# carries the rules itself and needs no database.
ENV TZ=CET-1CEST,M3.5.0,M10.5.0/3
# Caddy writes its state under these; /tmp is the one writable place once the
# root filesystem is read-only.
ENV XDG_CONFIG_HOME=/tmp/caddy/config XDG_DATA_HOME=/tmp/caddy/data

# Not root. 8080 rather than 80: an unprivileged port needs no capability.
USER 65532:65532
EXPOSE 8080
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
