---
title: "Nuestra herramienta señala Ed25519. Y firma con Ed25519."
standfirst: "Por qué no es una incoherencia, qué revela sobre lo post-cuántico que casi todo el mundo pasa por alto, y por qué no habrá cadena de bloques."
key: signer-avec-ce-qu-on-denonce
date: 2026-10-01
slug: firmar-con-lo-que-denunciamos
---

Escribimos una herramienta que inventaría la criptografía de un proyecto y dice, para cada uso, cuánto tiempo aguantará la protección. Se llama Sablier, es [abierta](https://github.com/mesa-black/sablier), y clasifica Ed25519 entre los algoritmos que hay que migrar: es una curva elíptica, así que el algoritmo de Shor acaba con ella.

Después llega el momento de firmar sus propios informes. Y ahí no hay salida: **PHP no ofrece ninguna firma post-cuántica.** RSA, ECDSA, Ed25519: los tres esquemas disponibles caen ante el mismo algoritmo de Shor. La elección nunca fue «Ed25519 o nada», sino «Ed25519 u otra igual de expuesta». Tomamos el más sano de los tres: moderno, compacto, sin parámetros que equivocar.

La herramienta firma, por tanto, con aquello mismo que señala. La tentación es ocultar el problema: firmar sin decirlo, o no firmar. Hicimos lo contrario: el informe imprime la contradicción, con el año de caducidad dentro. Porque mirarla de frente lleva directo a la distinción que casi todo el discurso post-cuántico se salta.

## La necesidad, antes que la solución

Un informe así acaba delante de alguien: un cliente, un auditor, un regulador. Entonces surgen tres preguntas, y son distintas.

¿Ha cambiado el contenido desde que se produjo? ¿Viene realmente de la herramienta y de la persona que se anuncian? ¿Existía en la fecha que muestra?

La primera pide una huella. La segunda, una firma. La tercera, un tercero que fecha, o un registro de solo adición.

## Por qué no será una cadena de bloques

Es la primera respuesta que aparece, y resuelve el único problema que no tenemos.

Una cadena de bloques existe para prescindir de terceros de confianza entre partes que no se fían entre sí, al precio de un gasto de cómputo y de una infraestructura permanente. Montar la propia es un nodo, es decir una persona: exactamente igual de creíble que la firma a la que pretendería sustituir, con una máquina que mantener para siempre. Usar una pública significa que la huella sale de la máquina, y nuestro informe promete por escrito no emitir nada.

La dosis justa cabía en tres cosas ya disponibles. Una huella de los hallazgos dentro del documento. Una firma separada, con una clave que controlamos. Y para una fecha oponible, una autoridad de sellado de tiempo normalizada, en una sola petición, el día en que alguien necesite de verdad una fecha que no le demos nosotros.

Un detalle de diseño que importa más de lo que parece: **no firmamos el archivo, firmamos los hallazgos.** Dos ejecuciones del mismo análisis producen bytes distintos —una fecha de renderizado, una duración— diciendo exactamente lo mismo. El mismo inventario en francés y en español da la misma huella. Firmar el archivo habría producido una alerta en cada ejecución y, en seis meses, la costumbre de ignorarlas.

Y la clave pública esperada vive en la declaración versionada del proyecto. Una firma que se verifica con la clave que viene a su lado solo demuestra una cosa: alguien tenía una clave. Ponerla bajo revisión de código convierte su cambio en un commit que alguien lee.

## La distinción que todo el mundo se salta

Queda la contradicción. Se disuelve en una frase: **una firma no se recolecta.**

El modelo de amenaza post-cuántico se llama *recolectar ahora, descifrar después*. Un adversario captura hoy tráfico cifrado y lo guarda hasta el día en que pueda abrirlo. Para un dato confidencial, la fecha de compromiso es entonces el día del cifrado, no el del ataque, y eso es lo que vuelve el plazo presente en vez de futuro.

Nada de eso se aplica a una firma. Nadie captura una firma para «descifrarla» después: dentro no hay nada. El día en que caiga la curva, un adversario podrá falsificar firmas nuevas, no antedatar las de 2026 en un mundo que ya ha visto morir el algoritmo y ha dejado de aceptarlas.

La consecuencia práctica es nítida y depende por completo de la vida útil de aquello que la firma debe demostrar.

Una firma cuya utilidad se mide en meses —un informe presentado este trimestre— queda perfectamente servida hoy por Ed25519. Una firma que deba seguir siendo verificable dentro de quince años no lo está en absoluto. Y esa segunda categoría tiene nombre: **anclas de confianza de larga duración**. Firma de código, autoridad de certificación interna, firmware, sellado de tiempo. Y, precisamente, un informe de conformidad que quizá haya que presentar ante un tribunal en 2041.

Es el mismo razonamiento que la herramienta aplica a los datos. La pregunta nunca es «¿este algoritmo es post-cuántico?». La pregunta es «¿cuánto tiempo tiene que aguantar?».

## Lo que dice el informe

Así que el informe lo dice, con el año dentro:

> Esta firma es Ed25519, que este mismo informe clasifica como vulnerable a lo cuántico. Una firma no se recolecta: aguanta mientras aguante la curva. Así que la única pregunta que importa es esta: ¿tendrá que demostrar la autenticidad de este informe después de 2035? Si es así, Ed25519 no bastará.

No es un aviso de conformidad, es una pregunta devuelta al lector, porque solo él conoce la respuesta. Nada en el código puede saber si un informe se archivará quince años o se tirará el trimestre siguiente.

Para los casos en que la respuesta es sí, la salida existe y es incluso elegante: las firmas basadas en funciones hash. No se apoyan en ninguna estructura matemática rica, solo en la solidez de SHA-256, lo que las hace inmunes a Shor por construcción. El precio está en bytes: de diez a cuarenta kilobytes por firma, frente a los sesenta y cuatro de Ed25519. Para un informe archivado quince años, es una factura ridícula. Es el paso siguiente previsto, y espera una necesidad real en lugar de un antojo.

## Lo que dio de sí

- **Los hallazgos firmados, no el archivo**: dos renderizados del mismo inventario, en dos idiomas, llevan la misma huella.
- **La clave pública esperada en la declaración versionada**: cambiarla es un commit revisado, no un detalle de línea de comandos.
- **Tres fallos de verificación distinguidos** —contenido modificado, clave distinta de la declarada, bloque ilegible— porque un «inválido» a secas no enseña nada a quien tiene que decidir.
- **Cero dependencias añadidas**, cero infraestructura, cero cadena de bloques.
- **La contradicción impresa en el documento**, con el año de caducidad dentro.

## Buenas prácticas

- Separar las tres necesidades antes de elegir herramienta: integridad, autenticidad, fecha oponible. No piden la misma respuesta, y confundirlas lleva a construir diez veces de más.
- Firmar lo que tiene sentido, no lo que tiene bytes: firmar un renderizado produce una alerta en cada ejecución, y una alerta sistemática acaba ignorada.
- Poner la clave pública esperada bajo revisión de código. Sin eso, la verificación solo demuestra que existe una clave.
- Juzgar una firma por la vida útil de lo que demuestra, no por la moda de su algoritmo.
- Escribir la reserva en el entregable, con sus cifras, y no en una nota al pie que nadie abre.

## Puntos de vigilancia

- **Una firma no fecha nada.** Dice quién, no cuándo: el campo de fecha es declarativo y lo firma quien lo escribe. Una fecha oponible exige un tercero, y decirlo es mejor que dejar creer lo contrario.
- Una cadena de bloques privada es un tercero de confianza disfrazado de protocolo. Si de todos modos hay que creerte bajo palabra, más vale firmar y asumirlo.
- Las firmas basadas en hash arrastran estado en algunas variantes: elegir una sin estado, so pena de convertir una copia de seguridad restaurada en una catástrofe silenciosa.
- **El riesgo real aquí no es el algoritmo, es la costumbre.** Una firma que nadie verifica no vale nada, sea cual sea su curva. El comando de verificación tiene que caber en una línea, o nadie lo escribirá.
