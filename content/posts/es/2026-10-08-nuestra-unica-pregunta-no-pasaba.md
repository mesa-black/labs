---
title: "Le hicimos nuestra única pregunta a un directivo real. No entendió nada."
standfirst: "Tres sesiones, tres fracasos, y una medida: 986 palabras que leer para responder a dos preguntas. Lo que decían de verdad las respuestas recibidas, por qué una respuesta plausible es peor que ninguna, y las seis correcciones que impuso."
key: la-seule-question-ne-passe-pas
date: 2026-10-08
slug: nuestra-unica-pregunta-no-pasaba
---

El 2 de octubre, un texto publicado aquí terminaba con una frase incómoda: todas las herramientas de este campo, la nuestra incluida, suponen que la duración de confidencialidad de los datos es un hecho *obtenible*, y nadie parece haber comprobado que una empresa real sepa enunciarla. Cerraba admitiendo que esa conclusión tampoco había sido validada con nadie.

Lo fue esta semana. Tres veces, con el directivo de una empresa que usa nuestras herramientas a diario. El resultado cabe en una frase, la suya:

> «Lo siento pero esto es jerga para mí, no sé qué quiere decir, no entiendo las frases. En resumen, estoy perdido.»

No es un problema de pedagogía, y no es un problema suyo. Es una medida sobre el instrumento, y se podía contar.

## La medida

[Sablier](https://github.com/mesa-black/sablier) lee un proyecto, inventaría lo que en él se cifra o se firma, y hace una sola pregunta por dominio de datos: *¿cuánto tiempo debe esto seguir siendo secreto?* La pregunta es deliberadamente no técnica, porque la respuesta es un hecho de negocio.

Para plantearla a distancia, la herramienta produce un archivo HTML autónomo: sin servidor, sin red, se abre, se responde, se devuelve un bloque de JSON. Pensado para las salas donde una entrevista en directo no puede entrar — una red cerrada, una máquina a la que nadie puede conectarse.

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
