---
title: "Verificamos nuestro argumento principal. Era falso desde 2015."
standfirst: "Lo que costó la verificación, lo que sobrevive a ella, y la única pregunta que nadie en este campo parece haber puesto a prueba."
key: notre-argument-etait-faux
date: 2026-10-02
slug: nuestro-argumento-era-falso
---

En el estudio de encuadre de [Sablier](https://github.com/mesa-black/sablier), publicado hace unos días, una frase sostenía todo lo demás. Decía que el hueco libre no era inventariar la criptografía de un proyecto —otros ya lo hacen— sino **enlazar ese inventario con la vida útil de los datos**, y que nadie lo hacía.

Esa frase es falsa. Lo descubrimos al verificarla, una semana tarde, y este texto cuenta lo que devolvió la verificación, porque es más útil que corregirla en silencio.

## Lo que devolvió la verificación

**La fórmula tiene nombre desde 2015.** Es la desigualdad de Mosca: `X + Y > Z`, donde X es cuánto tiempo debe permanecer confidencial el dato, Y cuánto durará la migración, y Z los años que faltan para que exista un computador cuántico relevante. Si la suma se pasa, hay una ventana durante la cual datos todavía sensibles ya no están protegidos. Es la referencia estándar de las direcciones de seguridad y de las agencias.

Lo que presentábamos como nuestro ángulo es esa desigualdad con Y eliminada y Z sustituida por el plazo reglamentario. Una simplificación de un marco conocido, no un hallazgo.

**Y el ángulo está ocupado.** Varios proyectos ya lo implementan sobre una base de código, con inventario, duración por activo y exposición calculada. Uno de ellos, un prototipo en Python de la misma edad y madurez que el nuestro, incluso produce un informe HTML autónomo imprimible en PDF. El parecido no acaba ahí.

## Inventario de lo que se cayó

Habíamos enumerado cuatro cosas que seguían siendo nuestras. Tres no aguantaron una hora de verificación.

**«Una firma no se recolecta.»** Era nuestro mejor argumento técnico: aplicar a una firma una desigualdad que habla de confidencialidad es puntuarla como si el tráfico pudiera capturarse y abrirse después, lo cual es falso. Salvo que el mismo proyecto hace exactamente esa distinción, y la formula mejor que nosotros: *un computador cuántico no puede des-firmar una versión de 2026*. Recalibra X según el uso —vida del dato para el cifrado, validez de la clave para la firma— y propone reemplazos distintos para el mismo algoritmo según lo que proteja.

**La sonda activa.** Nuestra diferencia funcional más demostrable: leer lo que un servidor negocia de verdad en lugar de lo que declara un archivo. También la hacen, con una precaución que nosotros no habíamos escrito: la sonda es el único componente que sale de la máquina, y su documentación la dibuja con línea discontinua por esa razón.

**La negativa a predecir.** Nosotros usamos el plazo reglamentario diciendo que no pronosticamos la llegada de un computador cuántico. Ellos modelan Z como una distribución de probabilidad y devuelven una mediana con su incertidumbre. Es más sofisticado que nuestra negativa, y probablemente más justo.

Lo que sobrevive no es una idea: **el ecosistema PHP**, que esas herramientas no cubren; **ningún servicio, ninguna base, un solo comando**, frente a una consola web local con historial; y **cero dependencias**, que en una herramienta que lee claves sigue siendo un argumento, aunque modesto.

Es mucho más pequeño de lo que habíamos escrito. Es lo que es cierto.

## La pregunta que nadie ha puesto a prueba

Pero la verificación devolvió más de lo que costó, y ahí está el fondo del asunto.

Todas estas herramientas, la nuestra incluida, se apoyan en la misma variable. Mosca la llama X. Nosotros, duración de confidencialidad. Otro, *security shelf life*. Y **todas la dan por disponible.** Los artículos ofrecen órdenes de magnitud por sector —diez años para pagos, cincuenta para historiales médicos— pero un orden de magnitud sectorial no es la respuesta de una empresa.

Y no hemos encontrado en ninguna parte rastro de alguien que haya verificado **que una empresa real sabe responder a esa pregunta.** No «cuál es la respuesta correcta», sino «¿lo sabe la persona que debería saberlo?». ¿Cuánto tarda en formularlo? ¿En cuántas categorías se atasca?

Si la respuesta es «lo sabe, en una hora», el campo está sano y se decidirá por la ejecución. Si la respuesta es «no lo sabe», entonces **todas estas herramientas están construidas sobre arena**, la nuestra la primera, y ningún detector adicional lo cambiará. Habría que plantear la pregunta de otro modo, probablemente partiendo de la conservación legal, que la gente conoce, en vez de la duración de confidencialidad, que nunca ha tenido que poner en palabras.

Eso se ha convertido en lo único que importa en este proyecto. No un detector más: una respuesta empírica a si la entrada existe.

## Lo que cambia en el método

Algo nos llamó la atención después. Escribimos nueve detectores, seis protocolos de sonda, tres idiomas de informe y un mecanismo de firma **antes** de verificar la única frase sobre la que se apoyaba todo. El orden estaba invertido, y lo estaba por una razón cómoda: construir es agradable, verificar no lo es, y una frase escrita por uno mismo parece verdadera.

La corrección no cuesta nada. La frase que vende se verifica antes que el código que entrega. Una búsqueda, veinte minutos, antes de la primera línea.

Y puesto que este proyecto se pasa el tiempo diciendo que un inventario que calla lo que no ha mirado fabrica falsa confianza, no podía conservar una reivindicación de exclusividad sin verificar en su propia documentación. El encuadre se corrigió en su sitio, con la tabla del estado del arte actualizada y la lista, más corta, de lo que queda.

## Lo que dio de sí

- **Una reivindicación de exclusividad retirada** de la documentación pública y sustituida por un estado del arte verificado y fechado.
- **Tres diferenciadores de cuatro descartados** en una hora de investigación, incluido el mejor.
- **Una pregunta abierta identificada** que todo el campo da por resuelta, y no lo está.
- **Cero líneas de código cambiadas**: la verificación no invalidó nada del producto, solo de su relato.

## Buenas prácticas

- Verificar la frase que vende antes de escribir el código que entrega. Es más corta de verificar y más cara de equivocar.
- Tratar una anterioridad descubierta como información y no como derrota: varias personas llegando de forma independiente a la misma idea en pocos meses es la mejor señal disponible de que la necesidad existe.
- Buscar lo que todo el mundo da por supuesto. En un campo joven, la hipótesis compartida es el sitio más rentable donde excavar.
- Corregir en el sitio, explicando. Una corrección silenciosa protege al autor; una corrección escrita protege al lector.

## Puntos de vigilancia

- **Descubrir una anterioridad no dice nada sobre la calidad de ejecución**, ni en un sentido ni en el otro. Un prototipo con una estrella no ocupa un mercado, y el nuestro tampoco.
- La tentación, tras una verificación así, es buscar un diferenciador de recambio hasta encontrarlo. Es el mismo error, cometido al revés.
- **Un orden de magnitud sectorial no es la respuesta de una empresa.** «Diez años para pagos» no dice cuánto tiempo deben permanecer secretos *sus* datos, y eso es justo lo que queda por demostrar.
- Nada de esto ha sido validado con un equipo externo. Incluida esta conclusión.
