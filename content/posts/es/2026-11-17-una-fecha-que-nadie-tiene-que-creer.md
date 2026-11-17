---
title: "Una fecha que nadie tiene que creer"
standfirst: "En octubre sacamos la fecha de nuestros informes de nuestro propio reloj y la confiamos a tres autoridades de sellado de tiempo. El propio informe admite el límite: sus sellos no valen nada más allá del RSA que los firma. Aquí está la continuación: una prueba de fecha hecha solo de SHA-256, que termina en un bloque de Bitcoin y que cualquiera puede verificar sin confiar en nadie. Y lo que no prueba, porque es la mitad del tema."
key: une-date-que-personne-n-a-besoin-de-croire
date: 2026-11-17
slug: una-fecha-que-nadie-tiene-que-creer
---

Nuestro artículo [«Una firma prueba quién y qué. Nunca cuándo.»](/es/cuando/) terminaba con una frase que el informe imprime junto a cada fecha atestiguada:

> Lo que el sello no prueba: nada más allá de RSA-4096, el esquema que lo firma.

Es honesto, y es incómodo. Una herramienta que dedica cuarenta páginas a explicar que [RSA](https://es.wikipedia.org/wiki/RSA) caduca no puede conformarse con fechar sus propias conclusiones con RSA. Como recordatorio: RSA es el algoritmo de clave pública más extendido, y un ordenador cuántico lo bastante grande lo rompería. El día en que eso ocurra tiene nombre, el [Q-Day](https://observatoire.mesa.black/comprendre#g-q-day), que nuestro [Observatorio post-cuántico](https://observatoire.mesa.black/comprendre) (en francés) explica paso a paso. Habíamos repartido la confianza entre tres autoridades, en tres jurisdicciones. Pero repartir la confianza no es prescindir de ella.

Luego la pregunta llegó de forma más directa: *¿por qué mi firma valdría más que una referencia pública? ¿No se puede fechar respecto a algo que todo el mundo puede verificar?*

Se puede. Pero la pregunta contiene dos, y hay que separarlas antes de responder.

## Quién y cuándo: dos preguntas, dos herramientas

Una firma responde a **quién**. La nuestra, por cierto, va acompañada de una firma post-cuántica, [ML-DSA](https://observatoire.mesa.black/comprendre#g-ml-dsa) (en francés). Nuestra declaración dice «estos datos no necesitan seguir siendo confidenciales», y todo el veredicto del informe depende de ello. Lo que importa es que una persona identificable se comprometa. Una referencia pública no puede hacerlo: cualquiera puede anclar cualquier archivo, lo que prueba que existía, no que alguien responda de él.

Una fecha responde a **cuándo**. Y ahí la pregunta es acertada: nada obliga a que la sostenga alguien a quien haya que creer. Una autoridad de sellado *firma* una fecha; también se puede *inscribir* un resumen en un registro público, donde ya nadie puede moverlo.

Así que mantenemos la firma para el **quién** y cambiamos de herramienta para el **cuándo**.

## OpenTimestamps, en una frase

[OpenTimestamps](https://opentimestamps.org), un protocolo abierto [publicado por Peter Todd en 2016](https://petertodd.org/2016/opentimestamps-announcement), une un resumen a un bloque de la cadena de [Bitcoin](https://es.wikipedia.org/wiki/Bitcoin) mediante una serie de operaciones de hash que cualquiera puede rehacer.

El mecanismo, sin la jerga:

1. Se envía el **resumen** de los hallazgos, treinta y dos bytes, a servidores públicos llamados **calendarios**. Como con una autoridad de sellado, el documento nunca sale. El cliente incluso le mezcla dieciséis bytes aleatorios antes del envío, para que un calendario no pueda relacionar un informe publicado con quien lo envió.
2. Cada calendario coloca los resúmenes que recibe en un **[árbol de Merkle](https://es.wikipedia.org/wiki/%C3%81rbol_de_Merkle)**: se calcula el hash de los resúmenes de dos en dos, luego el de los resultados de dos en dos, hasta que queda un único valor, la raíz.
3. Cada pocas horas, el calendario inscribe esa raíz en **una** transacción de Bitcoin. Una transacción para miles de resúmenes: por eso el servicio es gratuito.
4. Cuando esa transacción entra en un bloque, la prueba queda completa. Es la lista de hashes que lleva de **tu** resumen a la raíz de Merkle de **ese** bloque.

Verificar es rehacer esos hashes y comparar el resultado con la cabecera del bloque. No hay firma, ni certificado, ni autoridad en el camino. Lo que se obtiene tiene la misma forma que en octubre: *este resumen existía **a más tardar** cuando se minó ese bloque.*

## Por qué es más sólido que tres autoridades

**Ya no hay firma que creer.** Un sello [RFC 3161](https://www.rfc-editor.org/rfc/rfc3161) dice «la autoridad afirma». Una prueba OpenTimestamps dice «rehaz el cálculo». La diferencia no está en cuánto confías en el operador: ya no queda ningún operador cuya palabra cuente. Un calendario que cayera mañana, o que quisiera mentir, no podría quitarle nada a una prueba ya completa.

**Falsificar cuesta un bloque.** Para antedatar un documento, su resumen tendría que aparecer en un bloque antiguo. Ese bloque lo copian decenas de miles de nodos, y la cadena de trabajo que lo sigue representa años de electricidad. Para mostrar una cabecera falsa a un verificador que comprueba la [prueba de trabajo](https://es.wikipedia.org/wiki/Sistema_de_prueba_de_trabajo), habría que minar un bloque con la dificultad real. A los precios actuales eso supone del orden de **2,5 a 3 GWh de electricidad, es decir, de 120 000 a 320 000 €** según el rendimiento de las máquinas y el precio del kWh, sin contar el hardware, para engañar a una sola persona. (Calculado con la dificultad del bloque 976 238: 5,8 × 10²³ hashes por bloque, máquinas de 15 a 20 J/TH, un kWh a 5-10 céntimos.) Un verificador como el nuestro tolera una dificultad hasta cuatro veces menor que su último punto de referencia, para no rechazar los bloques honestos de un periodo más fácil: el precio mínimo para engañarlo es más bien de **30 000 a 80 000 €**.

**Y sobre todo, solo hay hash.** Es el punto que nos interesa, porque es el tema de todo este sitio. Un sello firmado con RSA-4096 cae el día en que un ordenador cuántico ejecute el [algoritmo de Shor](https://es.wikipedia.org/wiki/Algoritmo_de_Shor) a ese tamaño: entonces se podrán fabricar sellos con cualquier fecha. Una prueba OpenTimestamps solo contiene [SHA-256](https://es.wikipedia.org/wiki/SHA-2) (y a veces RIPEMD-160). Contra una función hash, un ordenador cuántico dispone del [algoritmo de Grover](https://es.wikipedia.org/wiki/Algoritmo_de_Grover), que **divide por dos** el margen de seguridad en lugar de anularlo. Encontrar otro documento que siga el mismo camino de hashes seguiría costando del orden de 2¹²⁸ operaciones, incluso con Grover. La prueba que producimos hoy tiene todas las razones para seguir siendo legible en 2040.

Una precisión, para no afirmar más de lo que es cierto: la seguridad *de Bitcoin* como moneda también descansa en ECDSA, que es vulnerable a la computación cuántica. Pero una prueba de fecha no depende de ello. Necesita que la cabecera del bloque exista y que haya costado trabajo, no que alguien pueda seguir gastando sus bitcoins.

## «Solo habéis cambiado una autoridad por una blockchain»

Es la objeción seria, y merece una respuesta precisa. **Queda un lugar donde se confía en alguien: quien te da la cabecera del bloque.**

Para verificar, hace falta la raíz de Merkle del bloque número N. Si tienes tu propio nodo de Bitcoin, la tienes, y no crees a nadie. Si no, se la pides a alguien, normalmente un explorador público, y ahí vuelve la confianza.

Esto es lo que hicimos en [Sablier](https://github.com/mesa-black/sablier), en este orden:

1. **Tu propio nodo**, si está configurado. No hace falta confiar.
2. Si no, **dos exploradores independientes** ([blockstream.info](https://blockstream.info) y [mempool.space](https://mempool.space)), **que deben devolver la misma cabecera**. Si discrepan, la verificación falla de forma visible.
3. Y en todos los casos, **se comprueba la propia cabecera**: su doble SHA-256 debe estar por debajo del objetivo de dificultad que declara, y esa dificultad debe superar un mínimo. Un explorador que quisiera mentir no puede inventarse una cabecera: tendría que **minarla**.

Esa es la diferencia con una autoridad: no creemos al explorador, comprobamos lo que da. Puede negarse a responder; no puede mentir a bajo coste.

Sin conexión, en modo `--airgap`, la cabecera se puede aportar a mano. Pasa entonces por las mismas comprobaciones.

## Lo que no prueba

Es la mitad del tema, y lo imprimimos en el informe en lugar de en una nota.

- **Quién.** Una prueba OpenTimestamps no dice nada del autor. Ese es el trabajo de la firma, y lo sigue siendo.
- **Una hora precisa.** La marca de tiempo de un bloque de Bitcoin la fija el minero, dentro de un margen: debe ser posterior a la mediana de los once bloques anteriores y no adelantarse más de dos horas ([las reglas exactas](https://en.bitcoin.it/wiki/Block_timestamp), en inglés). La fecha es por tanto exacta **con unas horas de margen**, no al segundo. Para decir «inventariado antes del 31 de diciembre de 2026» basta de sobra; para desempatar dos depósitos con diez minutos de diferencia, no.
- **De inmediato.** La prueba solo está completa cuando entra en un bloque, en menos de dos horas. Medido en el inventario de este sitio: enviado a las 5:46 UTC, inscrito en el bloque de las 6:11, prueba completa disponible antes de las 7:41, porque los calendarios esperan seis confirmaciones antes de entregarla. Mientras tanto, se tiene una promesa de los calendarios, no una prueba.
- **Que el documento no existía antes.** Como un sello RFC 3161, es una cota superior. Probar lo contrario («este informe no se fabricó de antemano») exigiría incluir un valor público e imprevisible del día, como un sorteo de la baliza [drand](https://drand.love). Es otra herramienta, y no la hemos construido.
- **Un valor jurídico.** Un sello de tiempo *cualificado* según eIDAS goza de una presunción de exactitud de la fecha ([Reglamento (UE) n.º 910/2014](https://eur-lex.europa.eu/legal-content/ES/TXT/?uri=CELEX:32014R0910), artículo 41). Una prueba OpenTimestamps no tiene ninguna: un juez puede admitirla, nada le obliga a ello.

## Las dos juntas, y por qué

De ahí nuestra decisión: **mantenemos los sellos RFC 3161 y añadimos el anclaje.** No responden al mismo horizonte.

| | sello RFC 3161 | prueba OpenTimestamps |
|---|---|---|
| en qué hay que creer | en la autoridad, y en el RSA que la firma | en nada, si tienes un nodo; si no, en una cabecera cuyo trabajo se comprueba |
| precisión | el segundo | unas horas |
| disponible | de inmediato | tras un bloque, en unas horas |
| reconocimiento jurídico | presunción, si el sello está cualificado según eIDAS | ninguno |
| frente a la computación cuántica | cae con RSA | solo descansa en el hash |

El sello sirve para un litigio en los próximos tres años. La prueba sirve para la pregunta que nos harán en 2040, cuando nadie podrá verificar una firma RSA de 2026 sin preguntarse quién la fabricó ayer.

## Hacerlo en casa, hoy, sin nosotros

Como en octubre, nada de esto necesita nuestra herramienta. Basta con el [cliente oficial](https://github.com/opentimestamps/opentimestamps-client).

Ejecutado en un contenedor vacío el 17 de noviembre de 2026:

```
$ pip install opentimestamps-client
$ ots stamp artefact.json
Submitting to remote calendar https://a.pool.opentimestamps.org
Submitting to remote calendar https://b.pool.opentimestamps.org
Submitting to remote calendar https://a.pool.eternitywall.com
Submitting to remote calendar https://ots.btc.catallaxy.com

$ ots upgrade artefact.json.ots
Calendar https://alice.btc.calendar.opentimestamps.org: Pending confirmation in Bitcoin blockchain
Failed! Timestamp not complete
```

Justo después del envío, aún no hay nada en un bloque. Unas horas después, `ots upgrade` completa el archivo. Queda la verificación, y ahí el cliente oficial es de lo más honesto: **sin un nodo de Bitcoin, no verifica nada por sí mismo.** Sobre la prueba del inventario de este sitio:

```
$ ots verify -d 8ecb829ccc278ef7ab3138f56e07ee13319cbb72ce1dabbfc58ee7b4d6b670b5 report.html.ots
Could not connect to Bitcoin node: Cookie file unusable ([Errno 2] No such file or directory: '/root/.bitcoin/.cookie') …

$ ots --no-bitcoin verify -d 8ecb829ccc278ef7ab3138f56e07ee13319cbb72ce1dabbfc58ee7b4d6b670b5 report.html.ots
Not checking Bitcoin attestation; Bitcoin disabled
To verify manually, check that Bitcoin block 976238 has merkleroot 962c81d774938b388799d7307f6f46a54e0c51b2f47a89f46b45aa5ea1c6a0b9
```

Esa verificación manual la hicimos en mempool.space y en blockstream.info: ambos dan `962c81d774938b38…` para el bloque 976 238. Es exactamente el punto donde vuelve la confianza, y lo que Sablier hace por ti, añadiendo la comprobación de la prueba de trabajo que el cliente no hace sin nodo.

Guarda el `.ots` junto al artefacto, como el `.tsr`. Tu lector no necesita ni a ti ni un formato propio.

## En Sablier

Todo esto cabe en una opción, junto a `--timestamp`:

```
sablier scan . --sign=sablier.key \
  --timestamp=http://time.certum.pl \
  --anchor=opentimestamps
```

A diferencia de `--timestamp`, aquí hay un valor por defecto: `opentimestamps` designa los calendarios públicos del proyecto. Para las autoridades rechazamos cualquier valor por defecto, porque elegir quién atestigua tus fechas es una decisión de confianza. Un calendario no puede mentir: en el peor de los casos no ancla, y la prueba se verifica sin él.

Las reglas son las mismas que en octubre:

- una prueba que ya ancla estos hallazgos se **conserva**, porque la más antigua es la única que vale;
- un calendario inaccesible se señala de forma visible, sin hacer fallar el análisis;
- el modo `--airgap` rechaza el anclaje, puesto que pasa por la red.

`sablier verify` recupera la prueba completa cuando aún está pendiente, y luego la verifica.

El inventario de este sitio está anclado desde el **17 de noviembre de 2026 a las 6:11 UTC**, en el bloque **976 238**. La prueba está en línea junto al informe, con sus tres sellos:

```
$ curl -sO https://mesa.black/audit/report.html.ots
$ sablier anchor report.html.ots --lang=es
  report.html.ots ancla la huella 8ecb829ccc278ef7ab3138f56e07ee13319cbb72ce1dabbfc58ee7b4d6b670b5
  anclado en la cadena Bitcoin en el bloque 976238, 17/11/2026 06:11 UTC — cabecera obtenida de blockstream.info + mempool.space, raíz de Merkle y prueba de trabajo verificadas aquí.
```

Y `sablier anchor <archivo>` ancla cualquier archivo: un SBOM, una declaración firmada, un acta. Cada versión de Sablier publica ahora el anclaje de su propio archivo.

## Buenas prácticas

- **Separa quién y cuándo.** Una firma compromete a una persona. Una fecha no necesita comprometer a nadie; necesita poder verificarse.
- **Ancla un resumen, no un archivo.** Salen treinta y dos bytes, nada más.
- **Conserva las dos pruebas.** El sello para los próximos años y el reconocimiento jurídico, el anclaje para el horizonte en que el RSA ya no valga nada.
- **Completa la prueba y consérvala.** Una prueba pendiente aún depende de los calendarios. Una prueba completa ya no depende de nadie, pero no se completa sola.
- **Comprueba la cabecera, no la creas.** Sin nodo, compara al menos dos fuentes y verifica la prueba de trabajo.

## Puntos de atención

- Una prueba OpenTimestamps acota una fecha por arriba, con unas horas de margen. Presentarla como una hora exacta es el tipo de aproximación que se vuelve en tu contra ante un lector atento.
- Un explorador público sigue siendo un tercero. Sin nodo y sin comprobar la prueba de trabajo, solo has desplazado la confianza una vez más.
- Una prueba pendiente no es una prueba. Un informe que dijera «anclado» antes del bloque diría más de lo que sabe.
- El anclaje no tiene ningún valor jurídico. Si necesitas una presunción ante un juez, necesitas además un sello de tiempo cualificado según eIDAS.
- Anclar no dice nada del autor. Un resumen anclado sin firma prueba que un archivo existía, no que alguien responda de él.

## Referencias

- **OpenTimestamps**: [el sitio del proyecto](https://opentimestamps.org), [el cliente oficial](https://github.com/opentimestamps/opentimestamps-client), [el anuncio de Peter Todd en 2016](https://petertodd.org/2016/opentimestamps-announcement) (en inglés).
- **Sellado por una autoridad**: [RFC 3161](https://www.rfc-editor.org/rfc/rfc3161); [Reglamento eIDAS (UE) n.º 910/2014](https://eur-lex.europa.eu/legal-content/ES/TXT/?uri=CELEX:32014R0910), artículo 41.
- **Bitcoin**: [las reglas de la marca de tiempo de los bloques](https://en.bitcoin.it/wiki/Block_timestamp) (en inglés), [la prueba de trabajo](https://es.wikipedia.org/wiki/Sistema_de_prueba_de_trabajo).
- **Criptografía**: [RSA](https://es.wikipedia.org/wiki/RSA), [el algoritmo de Shor](https://es.wikipedia.org/wiki/Algoritmo_de_Shor), [el algoritmo de Grover](https://es.wikipedia.org/wiki/Algoritmo_de_Grover), [SHA-2](https://es.wikipedia.org/wiki/SHA-2), [los árboles de Merkle](https://es.wikipedia.org/wiki/%C3%81rbol_de_Merkle).
- **Aleatoriedad pública**: [drand](https://drand.love) (en inglés).
- **Nuestro Observatorio post-cuántico** (en francés): [el Q-Day](https://observatoire.mesa.black/comprendre#g-q-day), [la criptografía post-cuántica](https://observatoire.mesa.black/comprendre#g-post-quantique), [«recolectar ahora, descifrar después»](https://observatoire.mesa.black/comprendre#g-harvest), [ML-DSA](https://observatoire.mesa.black/comprendre#g-ml-dsa), [RSA](https://observatoire.mesa.black/comprendre#g-rsa), [función hash](https://observatoire.mesa.black/comprendre#g-hachage), [sellado de tiempo](https://observatoire.mesa.black/comprendre#g-horodatage).
- **Aquí**: [«Una firma prueba quién y qué. Nunca cuándo.»](/es/cuando/), [Sablier](https://github.com/mesa-black/sablier), y [el inventario de este sitio](/audit/es/report.html).
