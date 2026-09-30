---
title: "Subir el SO bajo Docker: lo que sigue acoplado y lo que nada valida"
standfirst: "La aplicación vive en una imagen, así que la distribución no puede tocarla. Quedan cuatro puntos de acoplamiento, y uno de ellos está en un punto ciego que ningún pipeline cubre."
date: 2026-09-27
key: monter-l-os-sous-docker
slug: subir-el-so-bajo-docker
---

Show me the REX funciona en un único anfitrión: un Postgres, un Redis, un proxy frontal y la aplicación desplegada en blue-green — dos instancias idénticas, «azul» y «verde», de las que solo una sirve tráfico a la vez. La nueva versión se arranca en la que está en reposo y, cuando responde bien, se conmuta el proxy. Cuando escribimos esto, ese anfitrión sirve 52 casos publicados y algo más de 16.000 visualizaciones acumuladas.

Este montaje protege una entrega: si la nueva versión se porta mal, volver atrás lleva un segundo y nadie se entera. No protege nada frente a la máquina misma, porque las dos instancias viven en ese mismo anfitrión — si se para, se paran las dos.

El anfitrión único es una decisión asumida, no un descuido: sin redundancia mientras el tráfico no la justifique, y con el umbral de revisión por escrito — mil visitas al día. Por debajo, una segunda máquina cuesta mucho más en complejidad (replicación, conmutación, coherencia) de lo que aporta en disponibilidad, y la complejidad que nadie necesita todavía es lo más caro que se puede construir.

Pero asumir esa decisión crea una obligación. Si aceptas que un reinicio corta el servicio, te debes una cifra exacta de lo que cuesta. Eso es lo que hicimos mal esa noche, y volvemos sobre ello al final.

Subimos ese anfitrión de una versión de Ubuntu a la siguiente. La operación salió bien, y eso no es lo interesante. Lo interesante es que la contenerización ha reducido lo que una subida así puede romper a una lista muy corta, y que encontramos justo el elemento de esa lista que nada en nuestra cadena vigilaba.

## Lo que la contenerización desacopló de verdad

La aplicación es inmune a una subida de distribución, y conviene precisar por qué: no usa nada del anfitrión. Su PHP, sus extensiones, sus bibliotecas de sistema y su almacén de certificados viajan dentro de la imagen. Se puede sustituir por completo el `ca-certificates` del anfitrión: nuestras llamadas salientes a VIES, a la pasarela de pago y al almacenamiento de objetos no se enteran, porque nunca leen ese almacén.

Por eso los equipos han acabado tratando una subida de SO en un anfitrión de contenedores como rutina. Es casi cierto, y es ese «casi» el que cuesta.

## Los cuatro puntos de acoplamiento que quedan

Cuando ya has metido en imágenes todo lo que se podía, lo que sigue perteneciendo al anfitrión es una lista corta, y es la misma en cualquier servidor contenerizado:

1. **El núcleo.** Los contenedores lo comparten. Un salto mayor cambia el suelo bajo una base de datos mucho más que bajo un proceso web.
2. **El demonio Docker.** No está en tu imagen: es un paquete del anfitrión, instalado desde un repositorio de terceros.
3. **Las fuentes apt de ese demonio.** Lo que decide si el punto anterior volverá a recibir algún parche de seguridad.
4. **El contrato de reinicio.** Qué contenedores vuelven solos tras un arranque y cuáles, deliberadamente, no — la instancia en reposo, por ejemplo, debe quedarse abajo, o dos versiones de la aplicación se pelearían por la misma base de datos.

Nada más importa realmente. La lista es lo bastante corta como para revisarla a mano, antes y después — lo que hace imperdonable no revisarla.

## El único daño duradero cayó en el punto tres

Una subida de versión desactiva o elimina las fuentes apt de terceros. No es un fallo: esas fuentes están compiladas para la versión que abandonas, y mantenerlas activas durante el salto es la forma de romper el sistema. La herramienta hace bien, y lo advierte.

Lo que no hace es decírtelo después. Nuestra fuente de Docker había desaparecido. Nada se rompió: el demonio siguió funcionando, los contenedores con él, el sitio sirviendo. Pero el paquete instalado estaba compilado para la distribución anterior, y ya no quedaba ningún repositorio capaz de reemplazarlo. **El modo de fallo no es un servicio que se detiene; es un gestor de paquetes que se vuelve autoritativo y vacío a la vez.** Informa de que todo está al día, y dice la verdad sobre un universo que ya no puede ver.

Restaurar la fuente son cuatro líneas y ningún reinicio. Reveló de inmediato siete versiones menores de deriva acumuladas en silencio. Nada habría levantado la mano jamás: ni el demonio, que funciona; ni la monitorización que no tenemos; ni `apt`, que ya no tenía con qué comparar.

## El punto ciego: los ficheros compose

Y llegamos al hallazgo estructural, que es el que merece llevarse.

Nuestro servicio de base de datos no tenía política de reinicio. Tras un arranque, todos los demás contenedores habrían vuelto y Postgres no. El fallo es trivial: falta una línea. Su vida útil no lo es: llevaba meses ahí, y solo podía manifestarse en un reinicio del anfitrión, que no había ocurrido en todo ese tiempo.

La pregunta buena no es cómo se escribió. Es por qué nada lo detectó. Y la respuesta se generaliza mucho más allá de nuestro montaje: **los ficheros compose son la única configuración de producción que nadie posee.** No se cuecen en la imagen, así que la construcción nunca los ve. Ningún test los ejercita, porque los tests corren contra la aplicación, no contra la topología del anfitrión. Y nuestro job de despliegue ni siquiera los copia: abre una sesión SSH y lanza un script. Se editan en el repositorio, se aplican a mano y no los valida nada.

En una cadena por lo demás totalmente automatizada —tests, análisis estático, construcción de imagen, despliegue sin corte— ahí es donde un defecto puede dormir indefinidamente. No en el código que el pipeline lee veinte veces al día, sino en el puñado de líneas YAML que no abre nunca.

## Lo que el núcleo pudo romper, y lo que no verificamos

Un salto mayor de núcleo bajo un Postgres contenerizado merece algo más que «volvió a arrancar». Hay tres preguntas que hacerse, y solo podemos responder a dos:

- *El directorio de datos.* Vive en un volumen con nombre, en el mismo sistema de ficheros, con el mismo driver de almacenamiento. Nada se movió, y esa es la razón de que la subida fuera superable, no la suerte.
- *Los perfiles de confinamiento del demonio.* Los valores por defecto de seccomp y AppArmor vienen con el paquete Docker, no con la distribución, y por eso los contenedores encontraron el mismo entorno al otro lado.
- *La semántica de durabilidad.* Si un núcleo nuevo cambia algo para Postgres con nuestras opciones de montaje es una pregunta que no respondimos. Aguantó, lo que no prueba nada. Lo escribimos en lugar de reclamar una verificación que nunca hicimos.

## La medición ya existía

Queda la obligación planteada en la introducción: conocer el coste real del corte que decidimos aceptar. Dimos una cifra leyendo los registros de los contenedores: el intervalo entre el último error de un proceso y el arranque del siguiente. Ese número describe el anfitrión, no a los visitantes. Deja fuera el apagado anterior y el calentamiento posterior, y puede errar por un factor de tres.

Mientras tanto, todo nuestro tráfico pasa por una CDN que ya había registrado, petición a petición, exactamente lo que recibió la gente en esa ventana. **La medición que creíamos que nos faltaba ya la habían tomado por nosotros, en un aparato que pagábamos y nunca habíamos consultado.**

El reflejo a corregir no es «añadir instrumentación». Es inventariar lo que ya mide antes de añadir nada: la CDN, los registros del propio proxy, la consola del proveedor. Nuestros tropiezos de procedimiento de esa noche —un nombre de contenedor adivinado, variables de shell que no sobreviven a una reconexión SSH, un grep tan amplio que informó de 41 líneas para 2 errores— son todos de la misma familia y valen exactamente una frase: un runbook resuelve lo que necesita, nunca lo congela. Qué instancia está sirviendo es el caso de manual: cambia en cada despliegue.

## Por qué lo publicamos todo — y lo único que nos callamos

Un caso solo sirve si es concreto, así que este lleva las órdenes, los modos de fallo y las lagunas. Lo que plantea una pregunta legítima: ¿publicar todo eso no es entregarle un mapa a un atacante?

Nuestra regla cabe en una frase. **El problema nunca es nombrar una versión. Es nombrar una versión en la que sigues siendo vulnerable.**

«Estábamos en la versión X, nos costó esto, ya está corregido» es práctica habitual de post-mortem. El mismo texto publicado antes de la corrección es una debilidad todavía vigente con la diana puesta: un caso va firmado, nombra una empresa y un dominio. Así que primero corregir, después contar, y generalizar lo que no enseña nada. La *distancia* —siete versiones de deriva silenciosa— es la lección; la cadena de versión exacta de nuestro servidor no lo es. Lo que nunca se publica es la otra categoría, la que no se aprende pero sí se copia: nombres de máquina, rutas, la cadena de claves que descifra una copia. La frontera no es «sensible o inofensivo», es **¿esto enseña, o esto abre?**

## Lo que dio de sí

- **Cuatro puntos de acoplamiento** aislados entre una aplicación contenerizada y su anfitrión: núcleo, demonio, fuentes apt del demonio, contrato de reinicio. Lo bastante pocos para revisarlos a mano, antes y después.
- **Una vía de actualización congelada, restaurada**: el demonio había derivado siete versiones menores sin que nada pudiera señalarlo.
- **Un punto ciego estructural, nombrado**: los ficheros compose, la única configuración de producción que ninguna construcción, ningún test y ningún despliegue llegan a leer.
- **Una medición recuperada en lugar de construida**: la CDN ya había registrado lo que vieron los visitantes, gratis.

## Buenas prácticas

- Escribe tus puntos de acoplamiento una vez. En un anfitrión de contenedores son cuatro, siempre los mismos, y revisarlos lleva diez minutos.
- Tras una subida de versión, revisa primero las fuentes de terceros: un gestor de paquetes sin nada con qué comparar informa de que todo está al día, y no miente.
- Busca lo que tu automatización no posee. En una cadena totalmente automatizada, el defecto que sobrevive está en el fichero que el pipeline no abre nunca.
- Inventaría lo que ya mide —CDN, proxy, consola del proveedor— antes de añadir instrumentación. La cifra que te falta suele estar ya registrada.
- Un runbook resuelve, nunca congela: qué instancia está sirviendo, su nombre de contenedor y el id del servicio se piden en el momento.

## Puntos de vigilancia

- El fallo peligroso no es el servicio que se detiene, es el que sigue funcionando mientras pierde su capacidad de ser actualizado. No emite nada.
- «Volvió a arrancar» no prueba nada sobre durabilidad. Escribe las preguntas que no respondiste en vez de reclamar una verificación que no hiciste.
- Un defecto que solo puede manifestarse en un reinicio del anfitrión vive lo que dura el intervalo entre dos reinicios. En un servidor que se porta bien, son meses.
- Un registro interno dice cuándo murió un proceso, nunca cuándo dejaron de ser servidos los visitantes. Eso solo lo dice una medición tomada por delante de la pila.
- **Corrige antes de contar: un caso que describe una debilidad todavía abierta, firmado con tu nombre, no es transparencia: es un manual de instrucciones.**
