---
title: "Lo que ve su máquina"
standfirst: "Cuando usted abre un sitio en https, este prueba quién es con una clave. Stellar dibuja esa clave para que se note el día en que cambia. Quedaba un hueco: nuestro sitio mostraba la clave que recibe nuestro servidor, no la que recibe usted. Así lo hemos cerrado, explicado paso a paso, con lo que rompimos por el camino."
key: ce-que-votre-machine-voit
date: 2026-11-26
slug: lo-que-ve-su-maquina
---

Este artículo continúa [«Cada clave tiene su cielo»](/es/cada-clave-tiene-su-cielo/). Se lee sin haberlo leído: retomamos cada noción sobre la marcha.

## Primero, ¿de qué clave hablamos?

Cuando su navegador muestra un candado, ha ocurrido esto: el sitio le ha presentado un **certificado**, una especie de documento de identidad digital. En ese certificado hay una **clave pública**, un número muy grande que solo el sitio puede usar en el otro sentido, gracias a una clave privada que guarda para sí. Mientras el sitio pruebe que tiene la clave privada correspondiente, su navegador sabe que habla con él, y todo lo que circula va cifrado solo para él.

Esa clave pública es demasiado larga para leerse. Se calcula entonces un resumen, la **huella**: una serie de unos cincuenta caracteres, siempre la misma para la misma clave, y distinta en cuanto cambia un solo bit de la clave. Dos huellas idénticas son la misma clave.

Nadie compara cincuenta caracteres a ojo. Ese es el punto de partida de [Stellar](https://stellar.mesa.black): convierte la huella en una constelación con nombre. La misma clave, el mismo cielo. Otra clave, un cielo sin relación. Un cielo no se lee, se reconoce.

## El hueco que habíamos dejado

El peligro que se quiere ver se llama **interceptación**. Alguien se coloca entre usted y el sitio, en una red wifi por ejemplo, y se hace pasar por el sitio. Le presenta *su* clave en lugar de la del sitio, descifra lo que usted envía y luego lo transmite al sitio verdadero como si nada.

Una interceptación es, pues, dos claves para un mismo sitio: la verdadera, que el sitio sirve al resto del mundo, y la falsa, que le sirven a usted.

Pero nuestro sitio solo miraba desde un lugar. Cuando usted le pide el cielo de `ejemplo.es`, es *nuestro servidor* el que va a buscar la clave de `ejemplo.es`, desde nuestro centro de datos. Si alguien le intercepta a usted, en su cafetería, nuestro servidor no ve nada: recibe la clave verdadera y le dibuja un cielo tranquilizador. El artículo anterior lo decía en su lista de límites. Era el más incómodo.

## Mirar desde dos lugares

Para ver una interceptación hay que leer la clave **donde usted está**, y luego compararla con la que se ve desde otro sitio.

Un sitio web no puede hacer la primera mitad: una página no tiene derecho a leer el certificado de la conexión que la trajo. Una **extensión** del navegador, ese pequeño programa que se añade al navegador, sí puede. Pero en un solo navegador: Firefox da el certificado de cada página a sus extensiones; Chrome y Safari, no.

Así que escribimos una extensión para Firefox. Hace tres cosas.

**Dibuja el cielo de la página**, a partir de la clave que recibió su propia máquina. El cálculo se hace en su navegador, sin pedir nada a nadie.

**Recuerda.** Guarda el cielo que cada sitio mostraba en su última visita, y le avisa si ha cambiado. Un cambio no es necesariamente un ataque: un sitio renueva su certificado cada dos o tres meses, a menudo con una clave nueva. Pero es una razón para mirar.

**Con un clic, pregunta a nuestro servidor** qué clave recibe él del mismo sitio. Si las dos claves son idénticas, lo que usted ve coincide con lo que ve el resto del mundo. Si difieren, hay algo que entender.

Nada sale de su máquina antes de ese clic. Cuando usted pulsa, salen dos cosas: el nombre del sitio y la huella de su clave. La huella es pública por naturaleza, cualquiera puede leerla visitando el sitio. El nombre del sitio, en cambio, dice a nuestro servidor dónde está usted; la extensión lo declara al instalarse, y por eso nunca lo hace sin usted.

Unas palabras sobre la cocina. Para que la extensión dibuje exactamente el mismo cielo que el sitio, hubo que escribir el cálculo por tercera vez. Stellar está escrito en Go. Nuestra herramienta de inventario, [Sablier](https://github.com/mesa-black/sablier), está escrita en PHP y dibuja en sus informes el cielo de sus propias claves de firma: esa fue la segunda escritura. La extensión vive en un navegador, luego en JavaScript. Tres programas en tres lenguajes que deben dar el mismo dibujo, al trazo. El repositorio contiene treinta y dos cielos de referencia, y cada escritura se rechaza si dibuja uno solo de otra manera.

## Comparar una clave, a mano

La pregunta que hace la extensión puede hacerla usted sin ella. Imagine que un colega le dicta por teléfono la huella de la clave de su servidor, o se la entrega en una tarjeta. Usted quiere saber si el sitio que tiene delante presenta esa misma clave.

Bajo el cielo de un sitio, Stellar acepta ahora la clave que le dieron, en cualquier forma habitual, y responde sí o no: es la clave que este sitio sirve, o no lo es.

En pantalla, seis signos giran como una ruleta y se detienen uno tras otro, verdes cuando coinciden, rojos cuando no. Es agradable de mirar, y hay que decir lo que es: una **imagen de la respuesta**, no la respuesta. La respuesta sale de las dos huellas, comparadas enteras por el servidor.

La diferencia se mide en **bits**, la unidad de lo que hay que adivinar para hacer trampa. Los seis signos llevan 36: existen unos 54 000 millones de combinaciones, lo que parece enorme y está al alcance de alguien decidido, con máquinas alquiladas. Una huella lleva 256: un número de posibilidades que ninguna máquina recorrerá jamás. Dos claves distintas pueden, por tanto, tener los mismos seis signos. En ese caso la página muestra seis signos verdes, rechaza de todos modos, y explica por qué.

Una última salvaguarda: si usted pega por error una clave **privada**, la que nunca debe salir de su servidor, la página la rechaza antes de enviarla y vacía el campo.

## Seis signos y un mapa

A esos seis signos los llamamos la **puerta**. Cada clave saca seis, en un orden preciso, de un catálogo de sesenta y cuatro dibujos común a todos. Es una segunda manera de designar una clave: menos precisa que una huella, pero seis dibujos se dictan y se recuerdan mejor que cincuenta caracteres.

### ¿Por qué tan pocos bits?

Puede sorprender: 36 bits para la puerta, 33 para el nombre de un cielo, cuando la huella lleva 256. No es un límite técnico, es una elección, y merece una explicación.

**De dónde sale la cifra.** El primer signo se elige entre 64, el segundo entre los 63 que quedan, y así hasta el sexto. Eso da 64 × 63 × 62 × 61 × 60 × 59, unos 54 000 millones de puertas posibles. Hacen falta 36 bits para contar hasta ahí.

**Por qué no poner más.** Cada bit añadido se paga en comodidad. Doce signos en lugar de seis darían 70 bits, pero ya nadie dicta ni recuerda doce dibujos. En el otro extremo, la huella completa es imbatible, y es justamente la que nadie lee. Entre ambos, hay que elegir lo que un humano puede manejar de verdad. Seis signos es lo que nos pareció razonable para dictar y comparar; es un juicio, no una medida.

**Lo que eso impone.** Una herramienta que solo lleva 36 bits nunca debe decidir sola. La puerta y el nombre sirven para *notar* un cambio y para *designar* una clave en una conversación: «en mi máquina el sitio se llama Jilajix Figensis, ¿y en la tuya?». No sirven para *aceptar* una clave. Por eso la comparación descrita más arriba se hace sobre las huellas enteras, y los signos no son más que su imagen.

Se podría subir: ocho signos sacados de un catálogo de 256 darían 64 bits, fuera del alcance de un atacante corriente. No lo hicimos, porque un catálogo de 256 dibujos que nadie distingue no valdría más que una huella que nadie lee. Y aún no hemos medido lo que la gente distingue de verdad.

También sacamos de ellos un mapa en tres dimensiones: los sesenta y cuatro signos puestos sobre una esfera, los seis de la puerta unidos de dos en dos, y la clave situada en el punto más cercano a las tres líneas. Se pueden poner dos sitios en él y ver la distancia que los separa. El mapa es bonito y no aporta ninguna información más que los seis signos. Está escrito debajo.

## Lo que rompimos

**Publicamos un juego.** La primera versión invitaba a «marcar la puerta» pulsando los signos uno a uno, con pistas cuando uno se equivocaba. Era divertido y estaba fuera de lugar: un sitio que habla de seguridad no tiene por qué proponer una adivinanza cuya solución aparece justo encima. Lo retiramos al día siguiente, en favor de la comparación descrita más arriba, que conserva la animación y responde a una pregunta real.

**Tumbamos el sitio.** Stellar funciona a propósito con muy poca memoria, 64 MB, una fracción de lo que consume una sola pestaña del navegador. El día en que añadimos la descarga del cielo como imagen, dibujar la primera pidió 70 MB. El sistema detuvo el programa, dos veces seguidas. Dos minutos de caída, provocados por nuestra propia prueba. Desde entonces la memoria se mide antes de poner en línea, y una prueba automática falla si un dibujo supera su parte.

**Bloqueamos nuestro propio navegador.** Un sitio puede decir al navegador: «vuelve siempre por https, nunca en claro». Es una buena protección, y el navegador la recuerda durante un año. La activamos, incluso, por error, en la copia de trabajo que funciona en claro en la máquina del desarrollador. El navegador obedeció: exigía https a un programa que no lo hablaba, y ya no mostraba nada. El sitio solo da ahora esa consigna a quienes llegan a él por su dirección verdadera.

**Una prueba de carga encontró lo que nadie había visto.** Una prueba de carga consiste en enviar muchas peticiones a la vez para ver qué cede. Tres mil peticiones, cincuenta a la vez: todas las respuestas eran correctas, pero una de cada cien tardaba diez segundos. Cuando varios visitantes pedían la misma imagen en el mismo instante, cada uno esperaba su turno y luego la volvía a dibujar, en lugar de tomar la que el primero acababa de producir. Tras la corrección, la misma respuesta llega en menos de medio segundo.

**Una frase mostraba su propio accidente.** Durante unas horas, el párrafo que explica la comparación mostró a todos los visitantes un trozo de código en lugar del nombre del sitio. Ningún control leía ese párrafo. Una prueba abre ahora cada clase de página, en las tres lenguas, y rechaza el menor rastro de ese tipo.

**Ninguna prueba abría el sitio en un navegador.** En cada cambio, unos controles automáticos comprueban que nada se ha roto. Leían el código del sitio, no lo que un navegador hace con él: la animación, la memoria de las visitas, el rechazo de las claves privadas podían haberse roto sin que nada se encendiera. Los controles abren ahora el sitio en un Firefox de verdad, sin ventana, y actúan en él como un visitante: doce comprobaciones en cada cambio.

## Lo que atrapa

Tras una lista de tropiezos, hay que decir para qué sirve todo esto. La comparación entre lo que recibe su máquina y lo que recibe nuestro servidor atrapa **toda interceptación cercana a usted**. Son, con mucho, las más corrientes:

- **Un wifi público o un router doméstico comprometido.** Quien controla la red se coloca entre usted y el sitio. Su máquina recibe la clave de él; nuestro servidor, que no pasa por esa red, recibe la verdadera.
- **Un proxy de empresa.** Muchas organizaciones descifran el https de sus empleados para inspeccionarlo, y luego lo vuelven a cifrar con su propia clave. Es legal y a menudo está anunciado, rara vez comprendido. La extensión lo muestra sin ambigüedad: el cielo que usted ve no es el del sitio.
- **Un antivirus o un control parental** que hace lo mismo en su propia máquina.
- **Un programa malicioso** que ha instalado su propia autoridad de certificación, para que el candado siga verde mientras lo lee todo.

En estos cuatro casos el navegador muestra su candado de siempre y nada parece anormal. Es precisamente ahí donde un segundo punto de vista es útil: dos cielos distintos para un mismo sitio, visibles con un clic.

A eso se añade la memoria de la extensión. Incluso sin preguntar nada a nuestro servidor, le dice que un sitio ya no presenta la clave de ayer. Es el principio que protege las conexiones SSH desde hace treinta años: se confía en el primer encuentro, y se desconfía del cambio.

## Lo que no prueba

Estos límites son reales. No anulan lo anterior, dibujan su borde.

- **Una diferencia no siempre es una interceptación.** Es el límite más incómodo en la práctica. Un sitio muy grande reparte a sus visitantes entre muchos servidores, que pueden tener cada uno su certificado y su clave. En esos sitios, dos cielos distintos pueden ser perfectamente normales. En un sitio de tamaño corriente, que tiene una sola clave, dice mucho más. En ambos casos una diferencia es una razón para mirar de cerca, no un veredicto. Para despejar la duda, Stellar propone entonces buscar la clave que usted ve en los registros públicos donde se inscribe todo certificado emitido por una autoridad. Si figura ahí para ese nombre, es una de las claves del sitio. Si no figura, es serio: el certificado de un interceptor o de un proxy de empresa nunca se inscribe en ellos. Esa búsqueda envía el nombre del sitio a un servicio de terceros, así que solo se hace a petición.
- **Un interceptor situado cerca del sitio escapa a la comparación.** Si se encuentra en el camino de todos, en el proveedor de alojamiento por ejemplo, su máquina y nuestro servidor reciben la misma clave falsa. Es raro, exige otros medios que controlar un wifi, y es de lo que se ocupa la clave anunciada y firmada por el propietario en su DNS, el tema del artículo anterior. Los dos mecanismos se completan: uno mira cerca de usted, el otro cerca del sitio.
- **Nuestro servidor conoce el nombre del sitio** cuando usted pulsa. Es el precio de la comparación, y la razón por la que nunca ocurre sin usted.
- **Un solo navegador.** Mientras los demás no den el certificado a sus extensiones, no hay nada que adaptar.
- **La extensión aún no está en el catálogo de Mozilla.** Se instala desde el repositorio.
- **Los signos no sustituyen a la huella**, por las razones dadas más arriba.

## Fuentes

- **Nuestras**: [Stellar](https://stellar.mesa.black), [su código y la extensión](https://github.com/mesa-black/stellar), [Sablier](https://github.com/mesa-black/sablier), y el artículo anterior, [«Cada clave tiene su cielo»](/es/cada-clave-tiene-su-cielo/).
