---
title: "Nombramos la rama. Git empujó a main."
standfirst: "En un repositorio GitOps, main es producción. Una noche de octubre llegaron allí manifiestos que nadie había aprobado, con una etiqueta de imagen que no existía, sin que nadie hubiera escrito «main». Dos ajustes de Git, razonables cada uno, y un comando correcto en cualquier otro sitio."
key: push-sur-main
date: 2026-10-21
slug: nombramos-la-rama
draft: true
---

En un repositorio GitOps no hay botón de «desplegar». Argo CD lee la rama `main` de [k3s-stack](https://github.com/mesa-black/k3s-stack) y hace converger el clúster hacia lo que contiene. Empujar a `main` es poner en producción. Ese es todo el interés del modelo, y por eso todo pasa por una rama, se revisa y luego se fusiona.

El 19 de octubre a la 01:00, un commit llegó directamente a `main`: los manifiestos del pequeño servicio que muestra al lector el intercambio de claves que su navegador acaba de negociar. Nadie los había aprobado. Y su imagen llevaba una etiqueta provisional, escrita a la espera de que la CI construyera la real:

```yaml
images:
  - name: ghcr.io/mesa-black/handshake
    newTag: TO-BE-SET-AFTER-THE-FIRST-BUILD
```

Argo CD hizo exactamente lo que se le pide: desplegó. El pod se quedó en `ImagePullBackOff` nueve minutos, hasta que la CI escribió la etiqueta real a las 23:09 UTC. Nada grave esta vez: un servicio nuevo al que nadie llamaba todavía. Pero nadie había escrito `git push origin main`.

## El comando que se escribió

La rama se creó en un worktree, a partir de la rama remota, y luego se empujó nombrándola explícitamente. En esencia:

```bash
git worktree add -b feat/handshake ../k3s-handshake origin/HEAD
# … commit …
git push -u origin feat/handshake
```

Lo escribió el agente de código con el que trabajamos, y es el comando correcto en casi todas las configuraciones. No lo era en la nuestra, porque se cruzan dos ajustes.

**El primero es un valor por defecto de Git.** Una rama creada a partir de una rama remota (`origin/main`, u `origin/HEAD`, que apunta a ella) la sigue automáticamente: es `branch.autoSetupMerge`, activado por defecto. Nuestra `feat/handshake` tenía, pues, `main` como rama de seguimiento, sin que nadie lo pidiera.

**El segundo es una elección, en nuestro `~/.gitconfig`:**

```ini
[push]
    default = upstream
```

Con `upstream`, `git push` envía la rama actual a su rama de seguimiento. Es un ajuste legítimo, pensado para flujos en los que una rama local tiene otro nombre que la rama a la que alimenta. Con una rama que sigue a `main`, empuja a `main`.

Hasta aquí, nada sorprendente: es lo que dice la documentación para `git push` sin argumentos. La sorpresa está en otro sitio.

## Incluso nombrando la rama

Esperábamos que nombrar la rama, `git push -u origin feat/handshake`, se impusiera al ajuste. No es así. Lo reprodujimos en un repositorio desechable, con Git 2.54, creando cada vez una rama desde `origin/main`:

| `push.default` | `git push` | `git push -u origin mi-rama` |
|---|---|---|
| `simple`, el valor por defecto de Git | se niega, y explica por qué | crea `mi-rama` |
| `current` | crea la rama | crea `mi-rama` |
| `upstream` | **empuja a main** | **empuja a main** |

Con `upstream`, un destino ausente del comando se sustituye por la rama de seguimiento, incluso cuando se ha escrito el nombre de la rama de origen. El nombre escrito indica qué se envía, no adónde llega. Solo un destino escrito por completo cambia el resultado:

```bash
git push -u origin HEAD:refs/heads/feat/handshake   # sí crea la rama
```

El script, para comprobarlo sin nosotros:

```sh
#!/bin/sh
# Una rama creada desde origin/main, empujada nombrándola.
set -e
d=$(mktemp -d) && cd "$d"
git init -q --bare -b main remote.git
git clone -q remote.git clone 2>/dev/null && cd clone
git commit -q --allow-empty -m init && git push -q origin main
git switch -q -c mi-rama origin/main
git commit -q --allow-empty -m "mi-rama"
git -c push.default=upstream push -q -u origin mi-rama
git --git-dir=../remote.git for-each-ref --format='%(refname:short)' refs/heads
# muestra «main» sola: la rama no existe, el commit está en main
```

## Por qué es peor en un repositorio GitOps

En un repositorio de aplicación, este push habría puesto un commit sin revisar en `main`. Molesto, reparable, y la CI probablemente habría protestado antes de llegar a producción.

En un repositorio GitOps no hay ningún paso intermedio. El commit es el despliegue. Sin revisión, sin fusión, y en nuestro caso ni siquiera imagen: el controlador aplicó un manifiesto que hacía referencia a una etiqueta que aún no existía. El error no se ve en Git, donde todo parece normal. Se ve en el clúster.

Y tampoco se ve en el terminal. El push tiene éxito, sin aviso. La salida sí menciona `-> main`, en una línea que nadie lee tras un push que ha funcionado.

## Lo que cambiamos

Tres reglas, ahora escritas en las instrucciones del agente tanto como en las nuestras:

1. **Crear las ramas desde `main` local, no desde `origin/main`.** Una rama creada desde una rama local no sigue nada: `git worktree add -b feat/x ../x main`, o `--no-track` si se parte de todos modos de la remota.
2. **Empujar con un destino explícito:** `git push -u origin HEAD:refs/heads/feat/x`. Es más largo, y es la única forma que da el mismo resultado diga lo que diga `push.default`.
3. **Comprobar `origin/main` después de cada push de rama:** `git log origin/main -1`. Si el último commit es el nuestro, ya está en producción.

No cambiamos `push.default`. El ajuste sirve en otros sitios, y cambiarlo solo habría arreglado nuestro equipo. La regla protege también al agente, que comparte la misma configuración.

## Lo que todavía falta

La verdadera barrera no está en el puesto de trabajo. Está en el servidor: una regla de GitHub que rechace los push directos a `main` y exija una pull request, con una excepción para la clave de despliegue de la CI, que escribe las etiquetas de imagen.

Hoy, la rama `main` de k3s-stack no está protegida: ninguna regla sobre la rama. Todo lo anterior depende, pues, de la disciplina de quien empuja, humano o agente. Es lo próximo que hay que corregir, y lo escribimos aquí para que no se quede en una intención.

## Lo que dio de sí

- **Un push** a `main`, a la 01:00, que ningún comando había pedido en esos términos.
- **Nueve minutos** de un pod en `ImagePullBackOff` en producción, en un servicio al que nadie llamaba todavía.
- **Dos ajustes** implicados: `branch.autoSetupMerge`, por defecto, y `push.default = upstream`, por elección.
- **Un descubrimiento:** con `upstream`, nombrar la rama no cambia el destino.
- **Tres reglas** de trabajo, y una protección de rama todavía por poner.

## Buenas prácticas

- En un repositorio donde `main` es producción, proteger `main` en el servidor antes que nada. Una consigna protege a quien la conoce; una regla en el servidor protege a todos.
- Escribir el destino de un push completo (`HEAD:refs/heads/…`) en los scripts y en las instrucciones de un agente: es la única forma independiente de la configuración local.
- Crear las ramas de trabajo desde la rama local, para que no sigan nada por accidente.
- Después de un push, leer la línea que dice adónde llegó, o comprobar la rama remota.

## Puntos de atención

- **Un comando correcto solo lo es en una configuración.** `git push -u origin mi-rama` es correcto casi en todas partes. Un agente que lo aprendió en otro sitio lo escribirá en tu equipo, con tu `~/.gitconfig`.
- **Un ajuste heredado no aparece en ninguna revisión.** `push.default = upstream` vive en la configuración global, no en el repositorio. Nada lo señala hasta que ha producido su efecto.
- **Que un push tenga éxito no dice adónde llegó.** Git no avisa cuando el destino difiere del nombre escrito. La única huella es la línea `-> main`.
- **Quien responde es quien tiene la configuración.** El agente escribió el comando, pero fue nuestro equipo el que lo envió a `main`. Lo escribíamos hace unos días: [un agente puede hacerlo todo, no puede responder de lo que hizo](/es/quien-responde/).
