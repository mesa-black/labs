---
title: "La funcionalidad más barata es la que no se construye"
standfirst: "Tres señales que dicen «no escribas este código», y lo que nos ahorraron en un solo día."
date: 2026-09-27
key: le-code-qu-on-n-ecrit-pas
slug: el-codigo-que-no-escribimos
draft: true
---

La sobriedad digital se plantea casi siempre como un problema de optimización: imágenes más ligeras, mejor caché, una región más limpia. Todo cierto, todo marginal. En nuestra propia plataforma el alojamiento emite poco: un único servidor en Francia, en una de las redes eléctricas menos intensivas en carbono de Europa.

El desperdicio real está en otro sitio, y nadie lo mide: **el código escrito para nada**. Una migración que hay que rehacer, una herramienta comprada y abandonada, una funcionalidad publicada que nadie abre jamás. Eso cuesta incomparablemente más —en máquinas, en electricidad, en meses de trabajo— de lo que cualquier optimización de front ahorrará nunca.

Así que nos hicimos una pregunta que nunca habíamos formulado: ¿cómo se *decide* no construir algo?

## El reto: medimos lo que publicamos, nunca lo que evitamos

Todo equipo sabe celebrar una entrega. Ninguno sabe celebrar la funcionalidad que no escribió: no hay ticket, ni demo, ni línea en el changelog. La decisión no deja rastro, así que nunca se toma explícitamente: se aplaza, reunión tras reunión, hasta que alguien lo construye por cansancio.

Nos dimos tres señales. Aquí están, con lo que cada una ahorró en una jornada de trabajo corriente.

## Señal 1 — se rompió y nadie dijo nada

Nuestro aviso de «Novedades» para clientes lee sus entradas de los mensajes de commit marcados con `Client:`. Al auditarlo descubrimos que **42 de las 65 entradas jamás escritas no se habían mostrado nunca**: Git solo lee un trailer en el último párrafo del commit, y la línea casi siempre se escribía encima de la firma. Dos tercios de la funcionalidad llevaban semanas muertos.

El instinto es correr a arreglarlo. La pregunta útil va antes: *nadie se quejó*. Ni un cliente, ni una persona del equipo notó que faltaban dos tercios de sus novedades. Eso es información sobre la funcionalidad, no sobre el fallo.

Lo arreglamos, porque eran veinte líneas y el contenido ya existía. Pero si hubiera exigido una reescritura, la respuesta honesta habría sido eliminar el aviso. **Una funcionalidad rota que nadie reporta es candidata a desaparecer, no a repararse.**

## Señal 2 — el trabajo sería invisible

El mismo día, otra petición: traducir el espacio de cliente al inglés y al español. Medimos antes de escribir: 23 plantillas, ~426 cadenas, 83 mensajes flash, 192 etiquetas de formulario, 19 correos. Unas **700 cadenas, 1400 traducciones**.

Después buscamos al lector. No existía. Ninguna preferencia de idioma se guarda en la cuenta, y el selector solo está en la cabecera pública. Un visitante que navega en español y se conecta aterriza en una página en francés, sin más salida que editar la URL a mano. Habríamos producido 1400 traducciones inalcanzables.

Así que construimos el prerrequisito de dos horas —registrar el idioma, añadir el selector al espacio de cliente, respetarlo tras la conexión— y **nos detuvimos ahí**. La traducción se hará el día que un cliente la pida, y entonces se verá. El día que nadie la pida, no se escribirá nunca.

## Señal 3 — la disciplina cuesta menos que la herramienta

«Endurezcamos nuestro SRE» casi siempre acaba en lista de la compra: seguimiento de errores, monitorización, cuadros de mando. Lo teníamos todo aparcado por presupuesto, y el aparcamiento nos hizo un favor.

Porque la carencia real no era una herramienta. Una copia de seguridad cifrada se ejecutaba cada noche desde hacía semanas y **no se había restaurado ni una sola vez**. Hicimos el ejercicio: volcado, cifrado, descifrado, restauración en una base desechable, comparación de recuentos tabla por tabla, y comprobación de que una clave incorrecta falla de verdad. Salió bien, y no costó nada.

Además reveló dos puntos únicos de fallo que ningún cuadro de mando habría mostrado: producción y copias viven en la misma cuenta de proveedor, y la clave que descifra los secretos solo existe en línea. Ambas correcciones son gratuitas y llevan cinco minutos. **Medimos y ensayamos en lugar de comprar.**

## Lo que estas señales no dicen

«Nadie lo necesita» es también la excusa perfecta para no hacer nada, y una regla que solo sabe decir que no deja de ser una regla: es inercia. Dos salvaguardas la mantienen honesta.

Primero, la decisión debe *escribirse*, con su motivo. «No traducimos el espacio de cliente hasta que un cliente lo pida» es una decisión; «ya veremos» es una evitación que vuelve a cada reunión y cuesta atención cada vez.

Segundo, una funcionalidad sin uso no es automáticamente inútil: a veces lo que falta es visibilidad, no la necesidad. Antes de concluir, comprueba que la gente podía encontrarla. Nuestro aviso era invisible porque estaba roto, no porque sobrara.

## Y la parte ecológica, con honestidad

No podemos darte una cifra. No sabemos lo que emite nuestro alojamiento, ni lo que evitaron estas decisiones, e inventar un número tranquilizador sería exactamente el lavado verde que este caso critica.

Lo que sí podemos decir sin estirar nada: 1400 traducciones no escritas, una funcionalidad no reconstruida, una herramienta no comprada. Nada de eso aparecerá en un informe de carbono. Todo eso es trabajo que no consumirá jamás una máquina, un despliegue, una revisión, ni el mantenimiento que viene después durante años.

**La decisión más ecológica de aquel día fue no construir algo.**

## Lo que dio de sí

- **1400 traducciones no escritas**: entregado el prerrequisito de 2 horas, aplazadas las 23 páginas hasta que alguien las necesite.
- **42 entradas perdidas recuperadas** corrigiendo una regla de extracción, sin añadir ninguna funcionalidad.
- **0 € de herramientas nuevas**: un ejercicio de restauración y un runbook en lugar de una suscripción de monitorización.
- **Dos puntos únicos de fallo** detectados ensayando, no instrumentando.
- **Cada decisión por escrito**, con su motivo y lo que la reabriría.

## Buenas prácticas

- Antes de escribir, busca al lector. Si llegar hasta él exige un prerrequisito, construye solo el prerrequisito y párate ahí.
- Mide el trabajo antes de empezarlo: «700 cadenas» zanja un debate que «llevará un tiempo» mantiene vivo.
- Ensaya antes de comprar: una restauración realmente ejecutada enseña más que un cuadro de mando que nadie mira.
- Escribe la decisión de no construir, con su motivo; si no, no es una decisión, es un aplazamiento.

## Puntos de vigilancia

- «Nadie lo necesita» es también la excusa perfecta para la inercia: una regla que solo dice que no ha dejado de ser una regla.
- Una funcionalidad sin uso puede estar mal expuesta en lugar de sobrar: comprueba la visibilidad antes de concluir.
- Decidir no construir no es lo mismo que no decidir: solo lo primero deja de costar atención.
- No disfraces la frugalidad con cifras de carbono que no puedes calcular: el argumento se sostiene solo.
