---
title: "Criptografía: le hicimos nuestra única pregunta a un directivo real. No entendió nada."
standfirst: "Nuestra herramienta lee un proyecto, dice hasta cuándo aguantará cada protección, y pide a la empresa una sola cosa. Esto es lo que produce, y lo que pasó cuando le hicimos esa pregunta a alguien que no es informático: tres sesiones, tres fracasos, y 986 palabras que leer para responder a dos preguntas."
key: la-seule-question-ne-passe-pas
date: 2026-10-08
slug: criptografia-nuestra-unica-pregunta
---

Casi todo lo que protege hoy los datos de una empresa se apoya en cálculos fáciles en un sentido e impracticables en el otro. Un ordenador cuántico lo bastante potente hará posible el camino de vuelta, y los Estados han fijado fechas: los métodos actuales se desaconsejarán hacia 2030 y se prohibirán hacia 2035.

No es un problema para 2035, y ese es el punto que casi todo el mundo pasa por alto. Un adversario no necesita esperar: le basta con **copiar hoy** una copia de seguridad o un flujo, y guardarla hasta el día en que pueda abrirla. Es decir: un dato cifrado esta mañana que deba seguir siendo confidencial más allá de 2035 ya está perdido — cambiar de método más tarde protegerá lo que venga después, no a él.

[Sablier](https://github.com/mesa-black/sablier) es nuestra herramienta para poner esa frase en cifras sobre un proyecto real. Este texto cuenta lo que produce, y luego el fracaso de lo único que pide a un humano.

## Lo que hace la herramienta

Lee un repositorio — sin ejecutar nada, sin enviar nada — y anota cada lugar donde el código cifra, firma o resume algo: llamadas a bibliotecas, claves y certificados presentes en el árbol, configuración de servidor, scripts de despliegue, dependencias declaradas, y la infraestructura cuando está escrita en Terraform. Después cruza ese inventario con el tiempo que cada categoría de datos debe seguir siendo confidencial, y devuelve un veredicto por lugar.

Lanzada sobre un proyecto de ejemplo, esto es lo que da:

```
  /proyecto — 3 archivos leídos, 7 hallazgos, 0.0 s
  declaración: /proyecto/sablier.json

    COMPROMETIDO             1
    ROTO HOY                 1
    VIGILAR                  2
    CONFORME                 2
    PROBABLEMENTE NO CRIPTO  1

  → /proyecto/r.html
```

Cinco categorías, y dos que cuentan. Este es el hallazgo rojo, tal como lo escribe el informe:

> **COMPROMETIDO** — `deploy/backup.sh:3`
> Cifrado hoy, a conservar confidencial hasta 2036 — es decir 1 año después de la caducidad de RSA. Una captura hecha ahora será legible.

Y el que no tiene nada que ver con lo cuántico, porque un inventario que solo habla de 2035 se pierde lo que está roto desde hace veinte años:

> **ROTO HOY** — `src/Tokens.php:17`
> Roto clásicamente, al margen de lo cuántico. El plazo era ayer.
> *referencias CVE-2005-4900*

Un inventario que no concluye nada se archiva en una carpeta, así que el informe decide y ordena. El primer punto del plan nunca es «migrar»:

> **Decidir qué pasa con los datos ya emitidos.** Es la decisión que nadie toma, y viene antes de la migración. Los dominios afectados están protegidos por un algoritmo que no aguantará hasta el final de su duración de confidencialidad: lo que ya se cifró y transmitió está fuera del alcance de un parche. Tres salidas, y hay que elegir una explícitamente — volver a cifrar el stock existente, rotar las claves y reemitir lo que pueda reemitirse, o dejar por escrito que se acepta el riesgo. Migrar sin resolver esto protege los datos futuros y deja los antiguos expuestos sin que nadie lo haya decidido.

También sabe leer una fuga al revés. Con una fecha de compromiso, deja de razonar sobre lo que un adversario cosechará: cuenta lo que ya está en sus manos, y cuánto tiempo sigue haciendo daño.

> **Después de la fuga del 29/07/2026** — Lo que salió ya está en manos de alguien. La única protección que queda es el algoritmo, y tiene fecha de fin.
> *backups* — confidencialidad pedida: 10 años, es decir hasta 2036. El algoritmo que la protege caduca en 2035. 1 año de lo robado pasará a ser legible, y ninguna migración lo alcanza.
> *session tokens* — protegido por criptografía a la que lo cuántico no alcanza. Nada pasa a ser legible por ese lado.

El informe existe en dos versiones: una técnica, leída junto a un editor, y un documento de auditoría numerado que separa los hechos de la opinión, para la pieza que se presenta ante un tercero. Ambos imprimen lo que no miraron, porque un inventario que oculta sus puntos ciegos fabrica falsa seguridad. Todo corre en la máquina de quien lanza el comando: ningún dato sale, el código es MIT, y [los informes de ejemplo](https://github.com/mesa-black/sablier/tree/main/examples) están en el repositorio.

## Lo único que no puede adivinar

Uno de los veredictos anteriores dice «a conservar confidencial hasta 2036». Ese 2036 no viene del código. Viene de una duración que alguien declaró: diez años para esas copias de seguridad.

Es el eje de toda la herramienta, y ningún software puede adivinarlo. Una sesión de conexión dura horas, una factura diez años, un contrato treinta — y nada de eso es un hecho técnico. Así que la herramienta lo pregunta, en una sola pregunta, a alguien que conoce el negocio: *¿cuánto tiempo debe esto seguir siendo secreto?*

El 2 de octubre, un texto publicado aquí terminaba con una frase incómoda: todas las herramientas de este campo, la nuestra incluida, suponen que la duración de confidencialidad de los datos es un hecho *obtenible*, y nadie parece haber comprobado que una empresa real sepa enunciarla. Cerraba admitiendo que esa conclusión tampoco había sido validada con nadie.

Lo fue esta semana. Tres veces, con el directivo de una empresa que usa nuestras herramientas a diario. El resultado cabe en una frase, la suya:

> «Lo siento pero esto es jerga para mí, no sé qué quiere decir, no entiendo las frases. En resumen, estoy perdido.»

No es un problema de pedagogía, y no es un problema suyo. Es una medida sobre el instrumento, y se podía contar.

## La medida

Para plantear esa pregunta a distancia, la herramienta produce un archivo HTML autónomo: sin servidor, sin red, se abre, se responde, se devuelve un bloque de JSON. Pensado para las salas donde una entrevista en directo no puede entrar — una red cerrada, una máquina a la que nadie puede conectarse.

En el tercer intento conté lo que ese archivo daba a leer antes de poder responder. **986 palabras.** Para siete temas y dos preguntas por tema. Con la palabra *huella* cinco veces, y *algoritmo*, *plazo*, *régimen*, *declaración*, *fontanería* en el camino.

El detalle que importa: **la mayor parte de esas 986 palabras se había escrito el mismo día**, corrigiendo los dos fracasos anteriores. En cada pasada había añadido un párrafo por honestidad — lo que la herramienta no puede saber, por qué se hace esta pregunta, de dónde viene esta fecha, qué implica la respuesta. Cada uno defendible por separado. Todos juntos, un documento que nadie fuera del campo atraviesa.

La prosa llega un párrafo justificado a la vez. Por eso no se ve.

## Lo que decían de verdad las respuestas

La segunda sesión había producido un archivo de respuestas. Parecía completo: siete temas, siete respuestas, ninguna casilla vacía. Llegó con un comentario — «no he entendido nada» — y es leyéndolo línea por línea como aparece el problema real.

Siete temas, **la misma duración siete veces**: cinco años. Ninguna conservación legal declarada. Ninguna justificación escrita. Ningún nombre que dijera quién se comprometía. 182 segundos en total, con el tiempo por tema hundiéndose: 20,8 s, 36,1, 16,8, 15,9, 23,8, **8,9**, 10,6.

Los siete botones ofrecidos iban de 0 a 30 años. Cinco era el del medio.

Y ese cinco uniforme es demostrablemente falso en al menos dos puntos. El dominio que llamó «REX» es **contenido publicado**: su duración de confidencialidad es cero por construcción. El que llamó «Facturation» lleva diez años de archivo contable obligatorio — respondido cinco, con «conservación legal: 0» justo al lado.

**Una parte sí funcionó.** Renombró los siete temas con sus palabras: Login, Facturation, Information, REX, Profile, Sécurité, Paramètres. Es exactamente la tarea que se le pedía, y la hizo. El vocabulario de los *datos* no era el bloqueo. El de las *duraciones* sí.

Y las dos últimas preguntas del formulario — «una pregunta que esperaba y no se le hizo», «una palabra que no entendió» — volvieron vacías. 7,8 segundos en esa pantalla. Quien no entiende no rellena el campo donde decirlo.

## Por qué es peor que ninguna respuesta

Ese archivo no estaba vacío. Era **plausible**. Y la herramienta, al importarlo, mostraba «7 respuestas recuperadas», escribía una declaración, y no decía nada más.

Una declaración, en esta herramienta, es lo que compromete a una persona con una cifra: el informe de auditoría imprime junto a cada duración quién la declaró y cuándo. Convertir siete pulsaciones del botón del medio en una declaración fechada fabrica exactamente la falsa seguridad que el proyecto pasa el tiempo denunciando en otros sitios. Mejor ninguna declaración que una blanqueada.

Así que el modo de fallo peligroso de una herramienta así no es «la persona no sabe responder». Es «la persona produce algo que parece una respuesta».

## Las seis correcciones

**Los temas se nombran por su lugar, ya no por la criptografía que contienen.** Los temas se agrupaban por familia de algoritmos, lo que hace que un tema solo pudiera *nombrarse* por una familia: preguntábamos cuánto tiempo «cifrado de clave pública» y «huellas de contenido» debían seguir siendo confidenciales. Son mecanismos, no datos. Peor, el único tema que él habría sabido tratar — cinco directorios de negocio — había quedado aplastado dentro de uno de ellos.

**Las duraciones pasaron a ser consecuencias.** Ya no hay botones 0/1/3/5/10/20/30, sino cuatro frases: *es público, o sin consecuencia* / *nos incomodaría, hasta que pasara* / *un cliente podría reprochárnoslo, o irse* / *nos lo reprocharían durante años, o acabaría en los tribunales*. La aritmética es tarea de la herramienta.

**Y esas frases se anclan en la historia del proyecto.** Allí donde el repositorio sabe cuándo empezó — la fecha de autor más antigua de su registro git — las opciones nombran años vividos: *lo que escribíamos en 2023 seguiría siendo incómodo*, *incluso lo que escribíamos en 2019, al principio*. La opción más larga vale entonces la edad del proyecto, no una cifra redonda. Nadie estima bien siete años hacia delante; todo el mundo sabe decir si las facturas del primer año siguen contando.

**986 palabras pasaron a 235, y un test falla por encima de 260.** Un presupuesto, no una relectura: nada más detecta una prosa que llega de párrafo en párrafo. Un segundo test falla si una palabra del oficio vuelve al camino del lector. Todo lo retirado sigue escrito — en el informe de auditoría, leído por quien debe pesar las cifras, no por quien aporta una. Yo confundía a los dos lectores.

**Una pregunta entera desapareció: el régimen regulatorio.** Nadie fuera del campo elige entre NIST IR 8547, CNSA 2.0 y una posición de la ANSSI. La pregunta imprimía cinco líneas de siglas — y luego plazos de 2030 y 2035 justo debajo del año que la persona acababa de dar como fin de vida de la aplicación. Es la elección del auditor, en un archivo versionado, y la herramienta se lo recuerda cuando se queda en el valor por omisión.

**La herramienta señala ahora una respuesta uniforme.** Duraciones todas idénticas, ninguna justificación, nadie nombrado: lo dice, nombra las cifras, y recuerda que un contenido publicado y diez años de contabilidad no comparten duración. Señala, no se niega — juzgar si esas respuestas valen algo pertenece a quien dirigió la sesión.

## Lo que nos negamos a hacer

**Rellenar la respuesta por anticipado.** Era la corrección más tentadora: proponer una duración por categoría y pedir una confirmación. Un sí/no sobre una propuesta concreta es cognitivamente mucho más fácil que producir una duración.

Es también la forma más segura de obtener una declaración que nadie leyó. Un lector cansado acepta lo que hay en la casilla, y la casilla acaba firmada. El campo que nombra el dato ya no viene rellenado en absoluto, por la misma razón: llegaba con una familia de algoritmos, y rellenarlo con el nombre del directorio — «Entity» — no habría sido mejor.

## Lo que ha dado

- **Una hipótesis compartida por todo el campo, puesta a prueba**: una empresa no sabe enunciar espontáneamente la duración de confidencialidad de sus datos. No «todavía no»: no como se la preguntábamos.
- **Un modo de fallo con nombre**: la respuesta plausible. Un formulario que no obliga a pensar produce cifras, no información.
- **Tres fracasos con la misma persona**, que es una medida del instrumento y no de ella.
- **751 palabras retiradas** de un documento que había escrito creyendo ser honesto.

## Buenas prácticas

- Medir el documento antes de reescribirlo. «Demasiado técnico» es una impresión; 986 palabras y *huella* cinco veces es un defecto que se corrige.
- Poner un presupuesto donde la deriva es lenta. Un test que cuenta palabras detecta lo que ninguna relectura detecta, porque cada párrafo añadido es defendible en el momento en que se añade.
- Separar a los lectores. Las reservas de una herramienta honesta van al informe, leído por quien pesa las cifras — no al formulario, rellenado por quien aporta una.
- Pedir una consecuencia cuando se quiere una duración. La gente sabe lo que le costaría; no sabe convertirlo en años.
- Mirar los tiempos por pregunta. La curva descendente dice que se perdió a la persona, y lo dice antes que ella.

## Puntos de vigilancia

- **Una muestra de uno.** Un directivo, una empresa, un campo. Las seis correcciones se justifican por una observación, no por un estudio.
- Los títulos de los temas siguen siendo palabras de código — «Billing», «Entity». Traducirlas a vocabulario de negocio exigiría inventar lo que la herramienta no sabe; muestra el lugar y pide el nombre.
- **El archivo autónomo no se hizo para esto.** Existe para las redes cerradas, no para alguien solo frente a su correo. Tres fracasos seguidos dicen sobre todo que usamos el instrumento pensado para una sala aislada allí donde una conversación de veinte minutos, al lado, habría reformulado en voz alta lo que ninguna frase escrita alcanza.
- Nada garantiza que el cuarto intento pase. Lo que está garantizado es que sabremos medirlo.
