---
title: "No se puede asegurar Luhn. Por eso tu tarjeta tiene un CVV."
standfirst: "La fórmula de Luhn se ha explicado mil veces. Lo que se explica menos es que no protege de nada, que hacerla «más segura» es un error de categoría, y que el sector de los pagos lo entendió ya en los años noventa. También comprobamos qué ve nuestra propia herramienta cuando un código la usa como cerradura: nada. Está corregido, en parte, y esto es lo que queda."
key: on-ne-peut-pas-securiser-luhn
date: 2026-11-02
slug: no-se-puede-asegurar-luhn
---

El último dígito de un número de tarjeta no forma parte del número de cuenta. Es un dígito de control, calculado sobre los otros quince con una [fórmula](https://es.wikipedia.org/wiki/Algoritmo_de_Luhn) que Hans Peter Luhn, ingeniero de IBM, patentó en 1960. Está en los números de tarjeta, en los IMEI de los teléfonos y en cada identificador de empresa francés (SIREN y SIRET).

Cabe en tres líneas. Empezando por la derecha, se duplica un dígito de cada dos; cuando el doble pasa de 9, se le resta 9; se suma todo. El número es válido si la suma es múltiplo de 10. `79927398713` pasa, `79927398712` no.

Este texto parte de una idea que se oye a menudo, y que también tuvimos nosotros: ya que todo el mundo conoce la fórmula, ¿por qué no endurecerla? Cambiar su «modo cripto», ponerle una clave, convertirla en algo seguro. La respuesta corta es que no se puede, y el motivo es más útil que la propia fórmula.

## Lo que Luhn hace de verdad

Luhn no protege un número. Protege contra un error de tecleo: una persona que copia dieciséis dígitos de una tarjeta, por teléfono o en un teclado. Para ese trabajo es muy bueno, y lo comprobamos en lugar de copiarlo:

- detecta **cualquier error en un solo dígito**;
- detecta **cualquier inversión de dos dígitos vecinos, salvo `09` ↔ `90`**;
- se le escapan algunos «errores gemelos», cuando dos dígitos iguales se sustituyen por otros dos iguales: `22` ↔ `55`, `33` ↔ `66`, `44` ↔ `77`.

Es todo lo que se le pide. La fórmula no contiene ningún secreto: cualquiera la calcula, y es a propósito, porque es el formulario de pago el que tiene que poder decir «debe de haberse equivocado» antes de enviar nada.

Para un adversario, la consecuencia es inmediata. Un número al azar pasa el control **una vez de cada diez** (en cien mil sorteos, contamos un 10,2 %). Y quince dígitos elegidos siempre tienen un decimosexto que los hace válidos: basta con hacer la cuenta. Una protección que uno mismo puede calcular no protege de nada.

## Por qué no se puede endurecer

Supongamos que sustituimos la aritmética de Luhn por una función que recibe una clave secreta. El dígito de control pasa a ser imposible de calcular sin la clave: deseo concedido. Pero lo que hemos construido tiene nombre: es un **[código de autenticación de mensajes](https://es.wikipedia.org/wiki/C%C3%B3digo_de_autenticaci%C3%B3n_de_mensaje)**, un MAC. Y un MAC se juzga por su longitud.

Un dígito decimal son 3,3 bits. Un adversario que no conoce la clave acierta el dígito una vez de cada diez, exactamente como antes. Hemos añadido una clave que gestionar, rotar y proteger, y la probabilidad de falsificación no se ha movido ni un ápice.

Para alcanzar la seguridad que se espera de un MAC moderno, 128 bits, harían falta **39 dígitos de control**. Un número de tarjeta no tiene ni uno libre: el formato lo fija la norma ISO/IEC 7812, y los terminales y formularios de todo el mundo lo esperan tal cual. El presupuesto de seguridad de un identificador se cuenta en dígitos, y el de este es cero.

El problema, por tanto, no es que Luhn sea «débil». Hace perfectamente otra cosa. Proteger contra un accidente y proteger contra un adversario son dos oficios distintos, y el primero no es una versión rebajada del segundo.

## Lo que hizo el sector en su lugar

El sector de los pagos se hizo la misma pregunta, y respondió dejando a Luhn en paz y poniendo la seguridad al lado.

**El [CVV](https://es.wikipedia.org/wiki/C%C3%B3digo_de_seguridad_de_tarjetas_de_cr%C3%A9dito) es exactamente el «Luhn con clave» que buscábamos.** Los tres dígitos del dorso de la tarjeta los calcula el banco emisor, con un par de claves secretas (en [3DES](https://es.wikipedia.org/wiki/Triple_DES), dentro de un módulo de seguridad hardware), sobre el número, la fecha de caducidad y un código de servicio. Sin la clave, no se pueden calcular. Es un MAC.

Y tiene el defecto que acabamos de describir: tres dígitos, apenas 10 bits. Uno entre mil. Lo que lo hace utilizable no es la criptografía, sino todo lo que lo rodea. El banco bloquea la tarjeta tras unos pocos intentos fallidos, y las normas [PCI DSS](https://es.wikipedia.org/wiki/PCI_DSS) prohíben guardar el CVV después de la autorización. Cuando esas condiciones fallan, tres dígitos no aguantan: en 2016, investigadores de la Universidad de Newcastle demostraron que repartiendo los intentos entre cientos de comercios en línea, que no se comunican entre sí, se encontraba el CVV de una tarjeta en cuestión de segundos.

La lección es la misma que con Luhn, un paso más allá: **un MAC demasiado corto solo es seguro mientras alguien cuente los intentos**.

El sector lo entendió tan bien que acabó jugando con la otra variable. Desde mediados de los años 2010, algunos bancos ofrecen tarjetas con **CVV dinámico**: una pequeña pantalla en el dorso muestra un código que cambia a intervalos regulares, y las aplicaciones bancarias hacen lo mismo con las tarjetas virtuales. El código sigue teniendo tres dígitos. Nadie intentó alargarlo, porque el formato no lo permite. Se acortó su vida. Un CVV adivinado en cien comercios no sirve de nada si ha cambiado antes de que termine el ataque, y un CVV robado junto con el resto de la tarjeta caduca solo. Es el principio de los [códigos de un solo uso](https://es.wikipedia.org/wiki/Autenticaci%C3%B3n_con_contrase%C3%B1a_de_un_solo_uso) de nuestras aplicaciones de autenticación: cuando un secreto no puede alargarse, se le hace morir pronto.

**La tokenización es la otra respuesta.** Cuando Apple Pay o Google Pay registran una tarjeta, el teléfono no recibe el número real. Recibe un token emitido por la red, con forma de número de tarjeta, Luhn incluido, para que terminales y formularios lo acepten sin cambiar nada. El token no vale nada fuera del dispositivo y del contexto para los que se emitió. El cifrado que preserva el formato (FF1, normalizado por el NIST en el SP 800-38G) hace un trabajo parecido: cifra un número de dieciséis dígitos en otro número de dieciséis dígitos.

En ambos casos, Luhn sigue siendo lo que es: un control de tecleo sobre un número, ya sea real, token o cifrado. La seguridad vive en otra parte, en una clave, un módulo hardware y un contador de intentos.

Una precisión sobre la computación cuántica, ya que es nuestro tema habitual: nada de esto depende de ella. Un MAC se basa en una clave compartida, que un ordenador cuántico solo debilita marginalmente. Un CVV no necesita un ordenador cuántico para ser adivinado, necesita un comercio que no cuente los intentos.

## Lo que ve nuestra herramienta

[Sablier](https://github.com/mesa-black/sablier) lee un repositorio y anota toda la criptografía que encuentra en él. La pregunta natural era, por tanto: ¿qué dice de un código que usa un control de tecleo como cerradura? Escribimos un proyecto de cuatro archivos para saberlo, y ejecutamos sobre él la versión publicada, la 0.11.1, sin cambiar nada.

Los cuatro archivos:

- un vale aceptado solo por su dígito de control de Luhn, y abonado con 50 €;
- un enlace de restablecimiento de contraseña «firmado» con `crc32()`, y un token de autenticación verificado con `hash('crc32b', …)`;
- el mismo enlace, firmado correctamente con `hash_hmac('sha256', …)` y una clave secreta, como testigo;
- números de tarjeta guardados con `openssl_encrypt(…, 'des-ede3-cbc', …)`.

El informe:

```
  . — 4 archivos leídos, 3 hallazgos, 0.0 s
  declaración: ninguna (duraciones por defecto)

    ROTO HOY                 1
    CONFORME                 1
    PROBABLEMENTE FUERA DE TEMA 1
```

El 3DES se encuentra y se clasifica como roto, el [HMAC](https://es.wikipedia.org/wiki/HMAC) se encuentra y se clasifica como conforme. El vale, el enlace firmado con CRC y el token verificado con CRC **no aparecen en ninguna parte**. Y sin embargo son los tres únicos lugares del proyecto donde un desconocido puede obtener algo que no le pertenece.

Los motivos eran precisos, y estaban todos en el código:

- **Un Luhn escrito a mano no tiene firma.** Es un bucle, una multiplicación por dos y un módulo 10. No hay ninguna llamada de biblioteca que reconocer, y nunca lo habíamos intentado.
- **Ninguna regla buscaba `crc32()`.** Es una función de PHP, fácil de localizar, y a nadie se le había ocurrido.
- **`hash('crc32b', …)` se veía y luego se descartaba.** La regla que lee `hash()` encontraba la llamada, buscaba `crc32b` en su catálogo, no lo encontraba, y aplicaba una regla escrita precisamente contra los falsos positivos: *un algoritmo que no conocemos no nos corresponde juzgarlo.* Y sin embargo la línea contiene `$authToken`, una de las palabras que, en otra parte del mismo archivo, devuelven un hallazgo al rojo.
- **La palabra «checksum» hacía callar a la herramienta.** Sigue en la lista de indicios que señalan un identificador y no un control de seguridad. Un `md5()` sobre un token de restablecimiento, en una función llamada `checksum`, sale por tanto como «probablemente fuera de tema». En este caso concreto la conclusión se sostiene, porque las colisiones de MD5 no sirven de nada contra la huella de un token aleatorio. Pero el razonamiento es falso: la herramienta lo clasificó con las claves de caché porque leyó el nombre de la función, no porque entendiera lo que protege.

Hay algo peor que el silencio. Cada informe de Sablier termina con una sección «Lo que este informe no ha mirado», porque un inventario que calla sus ángulos muertos fabrica una falsa seguridad. Esa sección hablaba de los servicios gestionados, de los HSM, de las imágenes, del YAML. **No hablaba de las sumas de control.** El lector de ese informe tenía todos los motivos para creer que sus enlaces de restablecimiento se habían revisado.

No es un tropiezo puntual, es la consecuencia de una decisión que seguimos defendiendo. Las listas que hacen callar a la herramienta se construyeron a partir de una medición: veinte repositorios públicos, ochenta y nueve hallazgos clasificados como «rotos», ochenta y dos de los cuales eran claves de caché, nombres de archivo o identificadores. Sin ellas, los siete hallazgos reales se ahogaban. Con ellas, en treinta y un repositorios, solo quedan tres rojos falsos de veintiuno. Pero una lista que hace callar a la herramienta ante una palabra necesita la regla inversa, la que detecta cuándo esa palabra designa precisamente lo que se protege, y para «checksum» esa regla no existía.

## Lo que dice ahora la herramienta

El hallazgo que faltaba no era «CRC32 está roto». [CRC32](https://es.wikipedia.org/wiki/Verificaci%C3%B3n_de_redundancia_c%C3%ADclica) no está roto: hace muy bien aquello para lo que existe, comprobar que un archivo no se ha dañado por el camino. Ese hallazgo sería falso, y ese tipo de error enseña al lector a dejar de creer en los rojos. El hallazgo correcto trata del **uso**, y es el que Sablier imprime desde la 0.12.0:

> **ROTO HOY** — `src/ResetLink.php:8`
> Una suma de control protege contra un accidente, no contra alguien: no tiene clave y cualquiera puede recalcularla. El plazo era ayer.
> *Sustitución: HMAC-SHA-256 con una clave secreta, comparado con `hash_equals()`*

Sobre el mismo proyecto de cuatro archivos, el informe pasa de tres hallazgos a seis:

```
  . — 4 archivos leídos, 6 hallazgos, 0.0 s
  declaración: ninguna (duraciones por defecto)

    ROTO HOY                 4
    CONFORME                 1
    PROBABLEMENTE FUERA DE TEMA 1
```

Las tres sumas de control del enlace de restablecimiento y del token están en rojo, el 3DES también. El enlace firmado con una clave sigue conforme.

La regla es deliberadamente estrecha. Un `crc32()` solo se señala si está junto a algo que un desconocido querría falsificar: un token, un enlace de restablecimiento, una contraseña, un secreto, una firma, un vale, leído en la línea, en el nombre de la función y en el nombre del archivo. En cualquier otro sitio se queda callado: verificar una descarga, repartir sesiones entre servidores o calcular un ETag es exactamente para lo que sirve una suma de control. La prueba que acompaña la corrección contiene esos tres usos, y falla si alguno se pone en rojo. Sin ella, habríamos sustituido un silencio por ruido.

Lo que no está corregido es el propio Luhn. El vale aceptado por su dígito de control sigue sin aparecer: un bucle, un doble y un módulo no se distinguen de un cálculo ordinario, y reconocerlo por su forma es un proyecto aparte. Mientras tanto, el informe lo dice, en la sección de ángulos muertos, con todas las letras:

> Las sumas de control (CRC32, Adler-32) solo se señalan junto a un token, un enlace o un secreto. Un dígito de control de Luhn o un módulo escritos a mano nunca: nada los distingue de un cálculo ordinario, y un código que acepta un número por su dígito de control no aparece aquí.

Luhn no necesita que lo aseguren. Necesita que dejemos de pedirle que lo sea, y que una herramienta que dice hacer inventario lo diga cuando no sabe ver a alguien haciéndolo.
