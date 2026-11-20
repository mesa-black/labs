---
title: "Cada clave tiene su cielo"
standfirst: "La idea de partida era inventar una criptografía basada en las constelaciones. No se sostiene, y explicamos por qué. Lo que quedó de ella sí: Stellar dibuja la clave pública de un sitio como una constelación con nombre, para que una persona note el día en que cambia. Después hicimos que el DNS de nuestros propios sitios anunciara ese cielo, firmado y actualizado en cada renovación de certificado. Esto es lo que prueba y, sobre todo, lo que no prueba."
key: chaque-cle-a-son-ciel
date: 2026-11-20
slug: cada-clave-tiene-su-cielo
---

Todo empezó con una frase: *¿y si creáramos un nuevo modelo de criptografía, como RSA, pero basado en las constelaciones? Harán falta años luz antes de que una constelación desaparezca de nuestra vista.*

La imagen es bonita. No hace un sistema de cifrado, y más vale decir por qué antes de contar lo que construimos en su lugar.

## Por qué las estrellas no cifran nada

Un sistema de clave pública descansa sobre un problema que cualquiera puede plantear y que nadie sabe resolver al revés. En [RSA](https://es.wikipedia.org/wiki/RSA), es encontrar dos números primos grandes a partir de su producto. La seguridad viene de ahí: de un cálculo fácil en un sentido y fuera de alcance en el otro.

El cielo es lo contrario de un secreto. La posición de las estrellas es el dato más público que existe, medido y publicado desde hace siglos. No se puede esconder nada en él, y no contiene ningún problema difícil. Que una constelación dure millones de años no cambia nada: la duración de un objeto nunca ha protegido una clave.

Descartamos, pues, la idea de una «criptografía estelar». Inventar un cifrado propio es, además, lo primero que este oficio enseña a no hacer.

Pero la intuición contenía otra cosa, y esa era acertada: **una persona reconoce un cielo. No reconoce una cadena de caracteres.**

## El problema que nadie mira

Un sitio web demuestra quién es con una clave pública. Esa clave se resume en una huella, por ejemplo:

```
SHA256:9f3ntWkWWH7QVXvTp7oFXjDeN34LcvBOGX22U4Qu2ps
```

Nadie compara eso. Nadie lo recuerda de una visita a otra. El día en que la clave de un sitio cambia, porque se ha renovado un certificado o porque otro responde en su lugar, nada se lo indica al ojo humano.

Dibujar una huella no es una idea nueva, y no pretendemos que sea nuestra. OpenSSH sabe mostrar un pequeño dibujo de la clave de un servidor desde 2008 (la opción `VisualHostKey`, analizada en [«The drunken bishop»](http://www.dirk-loss.de/sshvis/drunken_bishop.pdf), en inglés). Los avatares geométricos de algunos sitios parten del mismo principio. Lo que les falta a esos dibujos es lo que permite hablar de ellos: un nombre.

## Lo que hace Stellar

[Stellar](https://stellar.mesa.black) toma la huella de una clave pública y obtiene de ella, siempre de la misma manera, una constelación:

- de siete a doce estrellas principales, cada una con una posición, un brillo y un color;
- trazos que las unen en una sola figura;
- un fondo de estrellas más débiles;
- y un nombre, por ejemplo *Zijizia Vudensis*.

La misma clave da siempre el mismo cielo. Una clave distinta, aunque sea en un solo bit, da otro, sin parecido. El cálculo no tiene nada de secreto: la huella pasa por [SHAKE256](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf), una función hash estándar, y cada estrella se extrae del resultado. El algoritmo está escrito en el [repositorio](https://github.com/mesa-black/stellar), con treinta y dos ejemplos de referencia para quien quiera reescribirlo en otro lenguaje. Nosotros mismos lo hicimos una vez, en PHP, para [Sablier](https://github.com/mesa-black/sablier).

Stellar no cifra nada ni sustituye nada. Es una manera de **mirar** una huella.

### Nombres inventados, y por qué

Los nombres son ficticios. Ninguno es el de una constelación real, y los dibujos tampoco corresponden a ninguna.

Los nombres reales no servirían. Existen ochenta y ocho constelaciones oficiales: claves sin relación llevarían el mismo nombre continuamente, y fabricar una clave que se llame *Orión* como la tuya exigiría unas decenas de intentos. El esquema inventado da unos 8400 millones de nombres. Están construidos para sonar como el latín de los astrónomos, porque el objetivo es poder decirlos en voz alta: «en mi lado, tu sitio se llama Zijizia Vudensis. ¿Y en el tuyo?»

## El mismo cielo allí donde aparece la clave

No hemos inventado ningún formato de huella. Stellar dibuja las que ya existen:

- para una clave SSH, la huella que da `ssh-keygen -l`;
- para un sitio web, el SHA-256 de la clave pública de su certificado.

La consecuencia es práctica: el cielo que muestra el sitio, el que dibuja la línea de comandos y el que obtiene un colega en su máquina son el mismo, porque parten de los mismos treinta y dos bytes.

```
$ stellar -host stellar.mesa.black
Name:        Zijizia Vudensis
Fingerprint: SHA256:9f3ntWkWWH7QVXvTp7oFXjDeN34LcvBOGX22U4Qu2ps
Key:         stellar.mesa.black:443 (X.509 certificate)
Certificate: ECDSA P-256, until 2027-02-18, Let's Encrypt YE2
Connection:  TLS 1.3, X25519MLKEM768 (post-quantum hybrid)
```

En el terminal, la constelación se dibuja encima de esas líneas. Los informes firmados de Sablier llevan también el cielo de su clave de firma, bajo el sello. No es el mismo que el del sitio que los publica, y es normal: son dos claves distintas, una firma un informe y la otra un certificado. Nos hicieron la pregunta el primer día, y desde entonces el informe imprime la huella completa junto al dibujo, para que se pueda comprobar cuál se está mirando.

## «Un cielo que cambia cada dos meses no sirve de nada»

Es la objeción seria, y nos ocupó más tiempo que el dibujo.

El sitio recuerda, en tu navegador y en ningún otro lugar, el cielo que cada nombre mostraba en tu última visita. Si el cielo ha cambiado, lo dice. Pero nuestros certificados se renuevan cada dos meses, con una clave nueva cada vez: no conservamos ninguna clave más tiempo del que vive un certificado. El cielo de nuestros sitios cambia, pues, seis veces al año, legítimamente. Una señal que salta seis veces al año por nada es una señal que se aprende a ignorar.

Hacía falta algo más que la memoria del visitante: **que el propietario del sitio diga él mismo qué cielo esperar.**

## El cielo que anuncia el propietario

Este mecanismo existe desde 2012 y no tuvimos que inventar nada. Un dominio puede publicar en su DNS un registro `TLSA` ([DANE, RFC 6698](https://www.rfc-editor.org/rfc/rfc6698)) que dice qué clave debe presentar su sitio. La forma recomendada, `3 1 1`, contiene el SHA-256 de la clave pública del certificado.

Es exactamente la huella de la que Stellar saca un cielo. «El cielo anunciado por el propietario» no es, por tanto, un formato nuestro: es un registro estándar, leído como un cielo. Stellar compara lo que el sitio muestra con lo que su DNS anuncia, y dice si es la misma clave, otra, o si el dominio no anuncia nada.

Faltaba hacerlo en casa. Tres piezas, colocadas el 20 de noviembre de 2026:

**La zona está firmada.** Sin [DNSSEC](https://www.rfc-editor.org/rfc/rfc4033), un registro `TLSA` no vale más que el DNS que lo transporta, es decir, poca cosa. `mesa.black` está firmado, y los resolutores que validan marcan sus respuestas como autenticadas.

**El anuncio sigue a la clave.** Un registro escrito a mano sería falso en la siguiente renovación. Por eso una tarea se ejecuta cada cinco minutos en nuestro clúster: lee la clave que sirve cada sitio, como lo haría un visitante, y corrige el registro si difiere. Nunca lee las claves privadas. Es el comando `stellar announce`, publicado con el resto.

**Solo nuestra cuenta puede obtener un certificado.** Dos registros [`CAA`](https://www.rfc-editor.org/rfc/rfc8659) autorizan a una única autoridad, para una sola cuenta y un solo método de validación ([RFC 8657](https://www.rfc-editor.org/rfc/rfc8657)), y prohíben los certificados comodín.

No esperamos a la próxima renovación para saber si el conjunto aguantaba. Provocamos una, en el propio sitio de Stellar. El certificado se emitió bajo la nueva regla `CAA`, el cielo del sitio pasó de *Kamubum Haparis* a *Zijizia Vudensis*, y unos tres minutos después el DNS anunciaba la nueva clave.

## Lo que no prueba

Es la mitad del asunto, como de costumbre.

- **El nombre solo no prueba nada.** Lleva unos 33 bits. Quien busque a propósito una clave con el mismo nombre que la tuya la encuentra en unos minutos de cálculo. El nombre sirve para hablar de un cielo, no para aceptarlo.
- **El dibujo tampoco, frente a alguien decidido.** Un ojo compara menos bits de los que contiene la huella. Quien puede fabricar muchas claves puede buscar una cuyo cielo se parezca al tuyo. El dibujo sirve para notar un cambio; cuando importa, se compara la huella completa.
- **No hemos hecho ningún estudio.** Nadie ha medido hasta qué punto la gente distingue dos de estas constelaciones. Mientras no se haga, cualquier afirmación sobre su legibilidad sería una opinión.
- **El sitio ve la clave desde nuestro servidor, no desde donde estás tú.** Alguien que interceptara tu propia conexión no es visible desde allí. Para saber qué recibe tu máquina, hay que ejecutar el comando en tu lado.
- **Stellar no valida DNSSEC por sí mismo.** Pregunta al resolutor de la máquina si lo ha hecho, y lo repite. «Firmado» quiere decir: ese resolutor lo ha verificado. En una red cuyo resolutor no valida, Stellar dice que no lo sabe, y tiene razón.
- **Ningún navegador aplica DANE.** El anuncio no bloquea a nadie: permite comprobar a quien quiera hacerlo. Por eso también es aceptable nuestro retraso: tras una renovación, el DNS anuncia la clave anterior durante diez minutos como máximo.
- **El DNS sigue siendo un tercero.** DNSSEC desplaza la confianza hacia el registro del dominio y la raíz. Es una segunda vía, independiente de las autoridades de certificación, y ese es todo su interés. No es la ausencia de confianza.

## Comprobarlo sin nosotros

Nada de lo anterior necesita Stellar. La huella de la clave que presenta un sitio:

```
$ openssl s_client -connect stellar.mesa.black:443 -servername stellar.mesa.black </dev/null 2>/dev/null \
    | openssl x509 -pubkey -noout \
    | openssl pkey -pubin -outform der \
    | openssl dgst -sha256
f5fde7b56916587ed0557bd3a7ba055e30de377e0b72f04e197db653842eda9b
```

Y lo que anuncia su propietario:

```
$ dig +short TLSA _443._tcp.stellar.mesa.black
3 1 1 F5FDE7B56916587ED0557BD3A7BA055E30DE377E0B72F04E197DB653 842EDA9B
```

Los dos valores son iguales. Tomados el 20 de noviembre de 2026; habrán cambiado en la próxima renovación, juntos si todo funciona. Con `dig +dnssec` ante un resolutor que valida, el indicador `ad` dice además que la respuesta está firmada.

Stellar solo añade una cosa a esos dos comandos: un dibujo y un nombre, para la persona que nunca los ejecutará.

## Probarlo

- **El sitio**: [stellar.mesa.black](https://stellar.mesa.black). Se escribe un nombre de dominio, una clave pública o una huella.
- **La línea de comandos**: un binario por plataforma en la [página de versiones](https://github.com/mesa-black/stellar/releases), sin dependencias. `stellar -host example.com`, `stellar ~/.ssh/id_ed25519.pub`.
- **En tu casa**: el sitio es el mismo binario (`stellar serve`), en una imagen de contenedor que no contiene nada más.

El código está bajo licencia MIT.

## Buenas prácticas

- **Compara la huella cuando importa.** El cielo hace notar un cambio, la huella lo prueba.
- **No aceptes nunca una clave por su nombre.** Di el nombre, mira el dibujo, comprueba la huella.
- **Anuncia tu clave, y haz que el anuncio la siga.** Un `TLSA` que no se actualiza en cada renovación se vuelve falso, y un registro falso es peor que ninguno.
- **Firma la zona antes de escribir en ella algo importante.** Sin DNSSEC, el anuncio vale lo que vale la red entre tú y tu resolutor.
- **Vigila desde fuera.** Nuestra tarea de seguimiento puede fallar en silencio. Una segunda, cada día, comprueba lo que vería un desconocido, y escribe cuando es falso.

## Puntos de atención

- Un `CAA` demasiado estricto solo se ve en la siguiente emisión. Después de escribirlo, renueva un certificado a propósito.
- Cambiar de servidores de nombres sin retirar antes la firma del registro deja un dominio inaccesible.
- Un token de API que modifica tu DNS es una llave de tu dominio. El nuestro está limitado a una zona y caduca.
- Buscar un nombre en los registros públicos de certificados envía ese nombre a un tercero. El sitio solo lo hace si lo pides, y lo dice.
- Un dibujo tranquiliza rápido. Es su virtud y su peligro: un cielo familiar no es una verificación.

## Referencias

- **DANE**: [RFC 6698](https://www.rfc-editor.org/rfc/rfc6698) y las recomendaciones de uso de la [RFC 7671](https://www.rfc-editor.org/rfc/rfc7671) (en inglés).
- **DNSSEC**: [RFC 4033](https://www.rfc-editor.org/rfc/rfc4033) (en inglés).
- **CAA**: [RFC 8659](https://www.rfc-editor.org/rfc/rfc8659), y la [RFC 8657](https://www.rfc-editor.org/rfc/rfc8657) para la cuenta y el método de validación (en inglés).
- **SHAKE256**: [FIPS 202](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf) (en inglés).
- **El dibujo de las claves en OpenSSH**: [«The drunken bishop»](http://www.dirk-loss.de/sshvis/drunken_bishop.pdf), Loss, Limmer y von Gernler, 2009 (en inglés).
- **Nuestro Observatorio post-cuántico** (en francés): [RSA](https://observatoire.mesa.black/comprendre#g-rsa), [la función hash](https://observatoire.mesa.black/comprendre#g-hachage).
- **En casa**: [Stellar](https://stellar.mesa.black) y [su código](https://github.com/mesa-black/stellar), [Sablier](https://github.com/mesa-black/sablier), y [el inventario de este sitio](/audit/es/report.html).
