---
title: "«Decimos lo que hacemos»: tres veces en dos días, este blog dijo algo falso."
standfirst: "Una firma que no cubría la página que sellaba. Tres huellas donde el documento prometía una. Un artículo citado como publicado que nunca salió. Cada una encontrada haciendo lo que la frase describía, y así es como — porque la transparencia no es una intención, es un dispositivo."
key: on-dit-ce-qu-on-fait
date: 2026-10-06
slug: decimos-lo-que-hacemos
corrections:
  - date: 2026-10-09
    note: >-
      El título de la sección 1 estaba en pasado — «una firma que no cubría la página que sellaba» — lo que daba a entender que ahora sí la cubre. El cuerpo decía lo contrario desde el primer día: la causa es estructural, ningún mecanismo la repara. Solo el título mantenía la ambigüedad; ahora está en presente. Señalado por un lector.
---

«Decimos lo que hacemos y hacemos lo que decimos» es una frase que se lee en muchísimos sitios, y escribirla no cuesta nada. Solo se vuelve interesante allí donde las dos mitades se separan — y siempre se separan, porque una afirmación se escribe una vez y el código sigue moviéndose.

Así que la pregunta útil no es «¿somos transparentes?». Es: **¿mediante qué dispositivo se detecta una frase falsa, y en cuánto tiempo?**

Aquí están las tres últimas, todas del 5 y 6 de octubre, todas impresas por nuestras propias herramientas.

## 1. Una firma que no cubre la página que sella, y nunca la cubrirá

Este sitio publica ahora su propio inventario criptográfico, producido por [Sablier](https://github.com/mesa-black/sablier) y firmado. El enlace está en la cabecera de cada página, el archivo `.sig` está al lado, y cuatro comandos bastan para comprobarlo sin nosotros.

Al añadir ese informe le escribimos una frase: *«el informe no ha cambiado desde que se firmó»*.

Una hora después, la comprobación de extremo a extremo — descargar el informe desde el sitio, su firma desde el sitio, la declaración desde GitHub, y verificar — devolvió esto:

```
signature valide, Ed25519 et post-quantique
  + ML-DSA-65 : vérifiée
```

Después **modificamos una palabra en el informe** y relanzamos el mismo comando. La misma respuesta: válida.

La frase era falsa, y era el peor tipo de falso: invitaba a un lector a confiar en unos bytes que la firma no toca. La causa es estructural y ningún mecanismo la repara — **un informe muestra su propia firma, así que no puede contenerla.** El HTML se escribe después de que el bloque exista, y firmar los bytes renderizados sería circular.

Lo que se firma es la huella de los *hallazgos*, que es lo correcto: dos renderizados del mismo inventario, en dos idiomas, deben dar el mismo valor. La única forma de atar una página a esa huella es repetir el análisis sobre la misma fuente y comparar — y **un repositorio público es precisamente lo que hace posible ese recálculo**. Eso pasó a ser la instrucción impresa, antes de la frase que dice qué establece la firma.

## 2. Tres huellas donde el documento prometía una

La corrección anterior añadió al informe la frase que faltaba: *«dos renderizados del mismo inventario, en dos idiomas, dan el mismo valor»*.

Al día siguiente, una pregunta sencilla — *si leo en español, ¿el enlace no debería apuntar a la auditoría en español?* — nos llevó a generar el informe en los tres idiomas. Las huellas salieron así:

```
fr  1839cd93…      en  abb8b217…      es  0e5b2727…
```

Tres valores, bajo un párrafo que prometía uno. Dos causas, una de ellas seria.

La pequeña: la etiqueta de un dominio *no declarado* está traducida — «non déclaré», «undeclared», «no declarado» — y entraba en el cálculo.

La grande: la sonda de red fabricaba sus hallazgos con frases traducidas, y el identificador de un hallazgo se calcula a partir de ese texto. Así que el mismo servidor producía un identificador distinto por idioma.

Por qué es peor que un desacuerdo de huella: ese identificador es lo que acepta un hallazgo — lo que escribe, en un archivo versionado, «vimos ese, y esta es la razón por la que lo dejamos». Un identificador que cambia con el idioma significa que **una decisión registrada en francés deja de aplicarse en silencio a un análisis lanzado en inglés**. Nada lo habría señalado: el hallazgo simplemente reaparece, sin su decisión.

En todo lo demás de esa herramienta, la prueba de un hallazgo es una línea de código fuente — intraducible por naturaleza. Desde la sonda es ahora el hecho que devolvió el apretón de manos, y la frase que lo explica vive en un campo aparte, como en todos los demás detectores.

## 3. Un artículo citado como publicado, y nunca salido

El texto programado para el 8 de octubre — aún sin salir cuando se escriben estas líneas — se abría con: *«El 2 de octubre, un texto publicado aquí terminaba con una frase incómoda…»*

Ese texto nunca salió. Estaba escrito, programado para el 2 de octubre, y lo retiramos el día anterior junto con otro. Comprobado: ausente del sitemap, ausente de las cuatro versiones subidas al servidor, y su URL responde 404.

Un lector que hubiera seguido la referencia no habría encontrado nada — el peor error posible en un artículo cuyo tema es comprobar lo que se afirma. La frase dice ahora lo que pasó: escrito, programado, retirado la víspera, y su última línea se mantuvo. **La retirada forma parte de la historia en lugar de estorbarla.**

## Lo que las tres tienen en común

Ninguna se encontró releyendo. Las tres se encontraron **haciendo lo que la frase describía**: alterar un informe publicado para ver si la firma se daba cuenta, generar el documento en los tres idiomas, seguir la propia referencia.

Es el único método que funciona, y tiene un nombre menos noble que «transparencia»: **comprobar en lugar de suponer**. El mismo error ocurrió dos veces en el utillaje durante esos dos días, de una forma aún más tonta — una comprobación que preguntaba por un código de estado en lugar de por un contenido. El servidor de desarrollo de PHP responde `200` con la página de inicio para una ruta que no existe, así que nuestro control informaba «en línea» de un artículo que había sido reconstruido fuera de existencia. **Un código de estado no es una verificación.**

## El dispositivo, ahora

Una frase falsa no se corrige prometiendo estar más atento. Se corrige haciendo automático su desmentido.

- **Un presupuesto de palabras.** El cuestionario de entrevista había llegado a 986 palabras de texto que leer para responder a dos preguntas por tema. Ahora son 235, y un test falla por encima de 260. Un segundo falla si una palabra del oficio vuelve al camino del lector. Porque la prosa llega de párrafo justificado en párrafo justificado, y nada más la detecta.
- **Tests sobre la afirmación**, no sobre el código: tres idiomas dan una huella; tres idiomas dan un identificador; ninguna ruta de archivo aparece ante la persona entrevistada; un informe sin firmar no afirma nada de lo que una firma probaría.
- **Artefactos repetibles.** El informe de este sitio, su firma y la declaración que designa la clave son públicos. El comando de verificación está impreso dentro del documento, y lo que establece — igual que lo que no establece — justo debajo.
- **Retiradas asumidas.** Dos artículos escritos, programados y después retirados la víspera. El mecanismo de publicación se corrigió en la misma pasada: una versión fechada que ningún artículo reclama ya se elimina del servidor, porque si no se serviría el día previsto con el texto retirado dentro.

## Lo que decidimos no medir

La transparencia sirve también para decir lo que no se hace, y por qué.

Este sitio **no cuenta sus visitas**. No hay ningún registro de acceso: comprobado, cero líneas de petición registradas. Un contador honesto es posible — el registro de Caddy, la dirección IP eliminada en origen, ningún dato personal conservado — pero contaría *peticiones*, no personas, y los robots inflarían la cifra. Un contador que anuncia «visitantes» contando peticiones es exactamente la falsa seguridad que el resto de este trabajo rechaza. Así que no.

Tampoco tiene **comentarios**. Harían falta un ejecutable en el servidor, una base de datos, moderación, antispam y el almacenamiento del nombre de otras personas — cinco cosas por cuya ausencia se define este sitio. En su lugar, una dirección al final de cada artículo. Cuesta una línea y filtra sola: quien se toma la molestia de escribir tiene algo que decir.

## Lo que ha dado

- **Tres afirmaciones falsas corregidas en dos días**, cada una con el test que falla si vuelve.
- **Un defecto serio encontrado de rebote**: decisiones de auditoría que se desvinculaban en silencio de su hallazgo según el idioma de ejecución.
- **Dos comprobaciones reescritas** porque medían un código de estado en lugar de un contenido.
- **Cero líneas de comunicación añadidas.** No hay una página de «nuestros compromisos» en este sitio, y no la habrá.

## Buenas prácticas

- Hacer lo que la frase describe, de verdad, una vez. Alterar el archivo firmado, generar en tres idiomas, seguir el propio enlace: ahí es donde caen las afirmaciones, no en la relectura.
- Escribir primero lo que una garantía **no** cubre. Es la mitad que todo el mundo olvida, y es la que fabrica la confianza mal puesta.
- Convertir cada promesa cumplida en un test que falle cuando deje de cumplirse. Una afirmación sin desmentido automático es una afirmación que un día será falsa sin que nadie lo sepa.
- Verificar un contenido, nunca un código de estado.
- Decir lo que se ha retirado. Una retirada explicada cuesta un párrafo; un agujero en un historial público cuesta la confianza que se intentaba construir.

## Puntos de vigilancia

- **Un dispositivo no es una virtud.** Nada de lo anterior garantiza la próxima frase. Solo garantiza que una afirmación ya probada no se degradará en silencio.
- Los tres errores de este texto se encontraron en dos días porque alguien **estaba usando** esas herramientas ese día. Una herramienta que no se usa conserva sus afirmaciones falsas indefinidamente, y ningún test se escribe en nuestro lugar.
- Publicar los propios errores tiene un coste que conviene nombrar: a quien lee deprisa le parece amateurismo. Lo hacemos igualmente, porque la alternativa — corregir en silencio — protege al autor y deja al lector con la versión falsa.
