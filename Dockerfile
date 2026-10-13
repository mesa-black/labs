# syntax=docker/dockerfile:1
#
# The blog as a container image: every dated version of the site, built once,
# served by Caddy. Which version is live is decided at run time by
# container/labs-switch (a sidecar in Kubernetes), exactly as the server's timer
# does today with a symlink.
#
#   podman build --build-arg SITE_DATE=$(TZ=Europe/Paris date +%F) -t labs .
#
# Two stages. The build stage runs on the BUILD machine's architecture
# ($BUILDPLATFORM): its output is HTML and PNG, the same whatever CPU produced
# it. Only the final stage exists per target architecture, and it only copies
# files — so a multi-arch image (amd64 for the server, arm64 for a laptop) never
# runs PHP under emulation.

# ------------------------------------------------------------------ build
FROM --platform=$BUILDPLATFORM php:8.4-cli AS build

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

WORKDIR /src
# Dependencies first, in their own layer: a new post does not reinstall them.
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist --no-autoloader
COPY . .
RUN composer dump-autoload --no-dev --classmap-authoritative

# The day the image is built for, passed in rather than read from the clock:
# a build cache keys layers on their instructions and inputs, never on the date,
# so a `RUN date` layer cached yesterday would silently build yesterday's site.
# A different SITE_DATE is a different input, so it invalidates the cache.
ARG SITE_DATE
ARG SITE_URL=https://mesa.black
# One complete version per publication date still ahead, plus the build day —
# what `make deploy` uploads today. Release dates are filtered to date-shaped
# lines: a stray PHP warning once became nine release directories.
RUN test -n "$SITE_DATE" || { echo "✗ --build-arg SITE_DATE=YYYY-MM-DD is required"; exit 1; } \
 && for d in $(php bin/build.php --release-dates | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') "$SITE_DATE"; do \
        SITE_URL="$SITE_URL" php bin/build.php --as-of="$d" >/dev/null \
     && mkdir -p /out/releases \
     && rm -rf "/out/releases/$d" && mv public "/out/releases/$d" \
     && printf '  version %s — %s pages\n' "$d" "$(find "/out/releases/$d" -name '*.html' | wc -l)"; \
    done

# ------------------------------------------------------------------ serve
FROM caddy:2.11.7-alpine

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
