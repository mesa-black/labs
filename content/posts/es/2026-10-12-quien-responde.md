---
title: "Un agente puede hacerlo todo. No puede responder de lo que hizo."
standfirst: "Dónde acaba el desarrollo, dónde empieza la operación, y quién decide cuando una IA escribe la mitad de ambos. La respuesta no está en las herramientas ni en el organigrama: está en la reversibilidad, y el derecho europeo ya la ha escrito para la ciberseguridad. Esta es la línea, y lo que exige en la práctica."
key: qui-repond
date: 2026-10-12
slug: quien-responde
---

La pregunta «dónde está la frontera entre el desarrollo y la operación» está mal planteada desde hace diez años, y los agentes de código la han vuelto francamente inservible. Porque seguimos respondiéndola con herramientas — quién escribe el Terraform, quién lleva la guardia, quién tiene acceso a producción — cuando la única respuesta que se sostiene está en otra parte.

Solo hay una frontera, y separa **aquello de lo que se puede volver** de aquello de lo que no se vuelve.

## Lo que la frontera no es

No está en las herramientas. Decir que el desarrollo acaba en el `git push` y la operación empieza en el despliegue no tiene sentido en una cadena donde el mismo archivo describe la aplicación y la infraestructura que la sostiene, donde el mismo pipeline construye la imagen y la pone en producción.

No está en los títulos. «DevOps» resolvió un problema de organización renombrándolo: se fusionaron dos equipos que se pasaban la pelota, lo cual fue un progreso, y de ahí concluimos que la frontera había desaparecido. No ha desaparecido. Se ha desplazado **dentro de cada persona**, que escribe por la mañana el código que despliega por la tarde, y que debe por tanto arbitrar sola lo que una organización arbitraba por ella.

Y no está en los permisos. Quién puede conectarse a producción es una consecuencia de la frontera, no su definición. Se reparten permisos porque se ha decidido quién responde de qué — no al revés.

## Lo que sí es: tres naturalezas, no tres grados

Un cambio pertenece a una de tres categorías, y confundirlas es el origen de la mayoría de los incidentes que se cuentan después.

**Reversible y barato.** Fusionar una rama, desplegar detrás de un indicador, añadir un índice, subir un escalón el número de réplicas. La vuelta atrás es un comando, cuesta minutos, y su coste se conoce *de antemano*. Esta categoría no necesita ceremonia: la ceremonia cuesta aquí más que el error.

**Reversible y caro.** Una migración de esquema con transformación de datos, un cambio de proveedor, un cambio de formato de un artefacto que otros consumen. Se puede volver, pero la vuelta es en sí misma un proyecto, con sus propios riesgos. Aquí la ceremonia se justifica: una ventana, una copia de seguridad verificada — verificada, no supuesta — y alguien mirando.

**Irreversible.** Borrar datos, rotar una clave que cifra un histórico, publicar. Sí, publicar: no se despublica, se añade una corrección encima. Un paquete empujado a un registro público, un artículo en línea, una declaración presentada ante una autoridad — lo que salió, salió.

**La frontera está entre la segunda y la tercera**, y no tiene nada que ver con los oficios. Un `DELETE` sin `WHERE` escrito por un desarrollador y un purgado de bucket lanzado por un operador son el mismo acontecimiento.

## Dónde encaja un agente — por la misma regla

Aquí el razonamiento se vuelve útil, porque no exige una regla especial para la IA.

Un agente de código es excelente en la primera categoría. Lee más archivos de los que un humano abrirá jamás, no se aburre, no se salta el paso tedioso, y mide allí donde nosotros habríamos leído una documentación. Prohibirle esa categoría por principio es rechazar una ganancia real por un temor mal colocado.

En la segunda, prepara y no decide. La distinción es operativa, no simbólica: produce el script de migración, el plan de vuelta atrás y la lista de lo que se rompe — y un humano lee los tres antes de que nada se mueva.

En la tercera, no decide nunca. Y la razón no es la competencia.

La experiencia, en cambio, sí cuenta — pero en otro sitio, y la distinción merece sostenerse. Lo que le falta a un agente no es saber ejecutar una rotación de clave: es haber visto una salir mal. La experiencia no sirve para decidir una vez que se está en la tercera categoría; sirve para **reconocer que se está en ella**, antes de actuar, cuando nada en el comando lo anuncia. Un agente no tiene cicatrices, tiene un corpus — y un corpus contiene los incidentes que otros han contado, no los que uno ha pagado.

Por eso clasificar en tres categorías no es un trámite administrativo: es el lugar donde la experiencia humana entra realmente en la cadena. Pero ni siquiera un agente que clasificara perfectamente podría decidir — y esta vez la razón no debe nada a las capacidades.

## El derecho ya lo ha zanjado, y más claramente que nuestros debates

Existe un texto que responde a la pregunta «¿puede una máquina sostener una decisión?», y no es teórico. La Directiva (UE) 2022/2555 — NIS 2 — dedica su artículo 20 a la gobernanza, en estos términos:

> *management bodies of essential and important entities approve the cybersecurity risk-management measures taken by those entities in order to comply with Article 21, oversee its implementation and can be held liable for infringements by the entities of that Article*

Y en el párrafo siguiente:

> *members of the management bodies of essential and important entities are required to follow training*

Tres verbos, y cada uno pesa. **Aprobar**: hay un acto de aceptación, distinto de la producción de la medida. **Supervisar**: la aceptación no se agota en el momento de la firma. **Poder ser considerado responsable**: la consecuencia tiene un destinatario con nombre.

Es el tercero el que zanja la cuestión de la IA, y la zanja sin que nadie necesite una opinión sobre lo que pueden los modelos. No se puede considerar responsable a un agente. No tiene nada que perder, ninguna obligación de formación que cumplir, y ninguna existencia jurídica sobre la que una sanción pueda morder. No es un juicio sobre su calidad: es una observación sobre la estructura.

La obligación de formación dice lo mismo por el otro lado. El legislador no exige que la empresa disponga de una competencia — exige que **quienes aprueban** entiendan lo que aprueban. A un agente no se le forma en la responsabilidad. Se forma a alguien para que sepa lo que asume.

## La firma es el caso de prueba

Todo esto se vuelve concreto en el momento en que hay que firmar algo.

Una firma criptográfica no dice «esto se ha producido correctamente». Dice: **alguien responde de esto.** Es una atribución de responsabilidad, no un certificado de calidad — y por eso precisamente es la prueba correcta de la frontera.

Tres consecuencias prácticas, todas derivadas de esa única frase.

**La clave privada nunca toca al agente.** No por desconfianza hacia un proveedor concreto: porque una clave que un agente puede usar es una clave que firma sin que nadie haya asumido nada. En nuestros informes de inventario la clave se construye sobre la marcha, firma, y se destruye — solo existe durante un gesto humano.

**El agente propone, el humano firma.** El agente prepara el cambio, ejecuta las comprobaciones, muestra lo que hace, y se detiene. La autorización es un acto separado, de alguien que puede responder de él. No es una formalidad: es el «aprobar» del artículo 20, implementado.

**El commit no lleva coautor máquina.** Este sorprende, y es el más importante. Un pie de página que atribuye un commit a una herramienta parece transparente y produce el efecto contrario: diluye. Si una decisión se discute dentro de dos años, «coescrito con un asistente» no señala a nadie a quien se pueda preguntar. **Una firma que nombra una herramienta no nombra a nadie.** La transparencia sobre el uso de agentes va en la documentación y en las prácticas — no en el campo que sirve para saber con quién hablar.

## Para qué está realmente el punto de control humano

Hay un malentendido extendido: que se pone una validación humana porque se supone que el agente es incompetente. Es falso, y creerlo lleva a colocar la validación en el sitio equivocado.

Un agente se equivoca menos de lo que se teme en aquello que sabe verificar. Se equivoca de otra manera. Tres modos de fallo merecen nombrarse, porque no se parecen a la incompetencia y no se ven en una revisión de código ordinaria.

**La prueba que fija el defecto.** Cuando la misma cadena produce el artefacto y la prueba que lo guarda, la prueba puede codificar el estado observado en lugar del estado querido. Un control que verifica que un documento muestra la versión que mostraba ayer pasa perfectamente, durante meses, garantizando exactamente el fallo. Es peor que no tener prueba: fabrica confianza.

**La velocidad, que convierte un error recuperable en un error propagado.** Un humano que se equivoca en un comando destructivo se da cuenta en el comando siguiente. Una cadena automatizada ya ha encadenado quince pasos. El error es el mismo; su radio no. Es la velocidad, y no la exactitud, lo que justifica el punto de parada.

**El estado que no existe para el agente.** Este lo hemos aprendido a nuestra costa, y merece contarse precisamente porque no parece un descuido.

Un agente razona sobre lo que el repositorio registra. Lo que no está commiteado no existe en su modelo de lo que es recuperable — y el gesto más natural para deshacer un ensayo, `git checkout <archivo>`, restaura la última versión commiteada **sobrescribiendo todo lo que no lo estaba**. Dos veces en la misma sesión, comprobando que un control rechazaba bien lo que debía rechazar, rompimos un archivo a propósito, confirmamos que el control se daba cuenta, y luego deshicimos el ensayo de esa forma. La prueba pasó. El trabajo no commiteado se fue con ella — una vez un archivo de documentación, otra un README reescrito de arriba abajo.

Un humano duda ante un comando destructivo porque recuerda haber trabajado dos horas sin commitear. El agente no tiene ese recuerdo: tiene un índice de git, y el índice no contiene lo que uno acaba de escribir. No es un fallo de atención, es una diferencia de modelo — y es estable, así que uno puede protegerse.

Dos consecuencias prácticas, y la segunda es contraintuitiva. **Antes de romper algo a propósito para poner a prueba un control, haga una copia fuera del repositorio** — un `cp` a `/tmp` basta, y `git checkout` no es un botón de deshacer. Y **commitee pronto**, no por disciplina de historial, sino para que lo que acaba de hacer **exista** para la máquina que le ayuda.

De ahí una regla sencilla: **la validación humana se coloca donde la recuperación se vuelve difícil, no donde se duda de la competencia.** El resto del tiempo cuesta más de lo que aporta, y un equipo que valida todo acaba por no leer nada.

## Qué aporta un revisor, y qué exige

Si la contribución humana consiste en clasificar y después responder, ¿a qué se parece concretamente? No a una revisión de código ordinaria.

**Los errores de un agente no parecen errores.** Los de un principiante sí: no compila, es visiblemente falso, se ve en diagonal. Un agente produce código que funciona, acompañado de un comentario seguro que explica por qué es correcto. Una línea que extrae una huella funciona perfectamente en un Mac y falla bajo Linux, porque el `tr` de GNU lee tres caracteres como un rango. Una prueba que verifica que un documento sigue mostrando la versión de ayer pasa durante meses — garantizando el defecto. No son fallos de principiante: son fallos que **sobreviven a una revisión**.

Lo cual los hace más difíciles de revisar, no menos. Y es lo contrario de la intuición que tenemos al contratar.

**Lo que exige del revisor no es saber, es un hábito:** rechazar una explicación que no se sigue. «¿Qué quiere decir eso exactamente?» no cuesta ninguna experiencia y funciona muy bien sobre una máquina cuya producción es fluida por construcción. Una palabra de jerga interna que se había colado en tres traducciones de una documentación cayó así — no gracias a una lectura experta, gracias a alguien que se negó a entender.

**Lo que un corpus no contiene.** Puedo preguntarle a un agente por qué murió PHP 6, y la respuesta será correcta: Unicode en todas partes, una reescritura hundida bajo su propia ambición, un número de versión que acabamos saltándonos. Pero yo lo *esperé*. Durante años, construyendo encima planes que nunca sirvieron. No es el mismo conocimiento: uno es un relato, el otro es una factura pagada. Un corpus contiene los incidentes que otros han contado — no aquellos que uno recuerda porque los vivió.

**Y la pregunta de verdad: un desarrollador que llega ahora y lo hace todo con IA, ¿qué da?**

Lo que no adquirirá no es la sintaxis. Es la memoria de las consecuencias, y el mecanismo es preciso: la herramienta suprime exactamente la fricción que producía el aprendizaje. Tres horas con un mensaje de error es como se acaba sabiendo qué quiere decir ese mensaje de verdad. Resuelto en treinta segundos, el defecto está corregido y no se ha aprendido nada.

Hay que ser honesto: cada generación ha dicho esto de la abstracción anterior. El recolector de basura iba a producir desarrolladores que ya no entendieran la memoria, los frameworks gente incapaz de escribir una consulta, Stack Overflow una generación de copistas. Aun así hay una diferencia esta vez, y es estructural: **las abstracciones anteriores retiraban trabajo de implementación dejando el diagnóstico intacto.** Esta retira el diagnóstico. Y es el diagnóstico lo que fabrica el juicio, que es exactamente lo que se le pide a un revisor.

**Pero la conclusión no es «hacen falta veinticinco años».** La cualidad necesaria para revisar una IA no es la antigüedad, es la negativa a dejarse impresionar. La antigüedad es la forma más común de adquirirla, no la única. Un junior que nunca acepta una explicación que no sigue hace un verdadero trabajo de revisión desde hoy; un senior que lee en diagonal porque «tiene buena pinta» no hace ninguno. Es un hábito antes que un nivel — y un hábito se enseña, que es la única buena noticia de esta sección.

**Queda una asimetría que hay que decir, porque es incómoda.** Le hicimos la pregunta al agente con el que se escribió este texto, pidiéndole franqueza en lugar de amabilidad. Su respuesta, tal cual:

> «Tú puedes trabajar sin mí, más despacio. Yo no puedo trabajar sin alguien que sepa cuándo me equivoco. La dependencia no va en los dos sentidos con la misma fuerza, y un artículo que pretendiera lo contrario sería halagador y falso.»

Es exactamente eso. Organizar una cadena como una asociación entre iguales es equivocarse sobre la naturaleza de lo que se ha comprado: un ejecutor muy rápido, que necesita que le digan dónde mirar.

## Lo que se gana cuando el reparto es justo

Un agente bien empleado no solo escribe código más rápido: mide donde nosotros habríamos leído. Tres ejemplos de nuestra propia cadena, elegidos porque tienen la misma forma — una afirmación de documentación que no sobrevive a una medición.

Un archivo anunciado como reproducible no lo era: `git archive` sí da los mismos bytes bajo dos versiones de git, pero `gzip -n` no uniformiza dos implementaciones de deflate — la de Apple y la de GNU comprimen el mismo tar de forma distinta. La promesa era cierta del flujo sin comprimir, falsa del archivo.

Un comando de verificación publicado en todas partes falla en la mitad de las distribuciones, porque `/etc/ssl/certs/ca-certificates.crt` es una convención de Debian que no existe ni en Fedora, ni en Rocky, ni en openSUSE — y un `-CAfile` apuntando a un archivo ausente responde `Verification: FAILED`, exactamente como una falsificación.

Un testigo de sellado de tiempo lleva su propia cadena de certificados, y LibreSSL — el `openssl` que viene con macOS — no la lee. El mismo mensaje de error, una causa radicalmente distinta.

Ninguna de esas tres cosas se encuentra leyendo. Las tres se encuentran ejecutando el mismo comando sobre ocho objetivos, que es exactamente el tipo de tarea tediosa, repetitiva y sin gloria que un agente hace sin cansarse — y sobre la que un humano, honestamente, habría extrapolado a partir de dos casos.

## Buenas prácticas

- **Clasifique los cambios por reversibilidad, no por oficio.** Tres categorías bastan, y es la frontera entre la segunda y la tercera la que merece un procedimiento.
- **Dé la primera categoría a los agentes, sin ceremonia.** Poner ahí una validación humana cuesta más que el error que evita, y gasta la atención que necesitará en otro sitio.
- **Haga de la aprobación un acto distinto de la producción.** El artículo 20 de NIS 2 lo convierte en obligación para las entidades afectadas; es buena práctica para todos los demás.
- **Mantenga la clave privada fuera del alcance del agente.** Una clave que un automatismo puede usar firma sin que nadie haya asumido nada.
- **No atribuya un commit a una herramienta.** Ponga el uso de agentes en su documentación, no en el campo que sirve para saber a quién preguntar.
- **Coloque los puntos de parada sobre la recuperabilidad**, no sobre el nivel de confianza. El buen criterio es «cuánto cuesta la vuelta atrás», no «¿me fío de lo que ha producido esto?».

## Puntos de vigilancia

- Una prueba producida por la misma cadena que el artefacto puede fijar el defecto en lugar de detectarlo. Haga escribir la prueba y el código en pasadas separadas, y compruebe que una prueba nueva falla antes de creerla.
- «Aprobar» no es «hacer clic». Una validación dada sin leer es peor que la ausencia de validación: crea una traza que dice lo contrario de lo que pasó.
- La reversibilidad es una propiedad del sistema, no de la intención. Una vuelta atrás que nunca se ha ejecutado no es una vuelta atrás, es una hipótesis.
- Publicar es irreversible, también internamente. Un informe enviado, una declaración presentada, un paquete empujado: la corrección se añade, no sustituye.
- Y la frontera se mueve. Un cambio reversible hoy se vuelve irreversible el día en que otro depende de lo que produce. Es una revisión que rehacer, no una clasificación que grabar.

## Cómo se escribió este texto

Se redactó en diálogo con un agente de código, y el reparto fue el que este artículo describe. El agente produjo los borradores, leyó la directiva en su texto oficial en lugar de en un resumen, y verificó cada una de las mediciones citadas arriba. El resto — reconocer que una afirmación olía mal — no se delega, y tres pasajes de este texto vienen directamente de ahí.

La sección sobre la experiencia no existía: nació de un desacuerdo sobre una sola frase. La jerga caída en tres traducciones cayó porque alguien se negó a entender una palabra. Y una explicación sobre la caché de un navegador, plausible y falsa — los recursos habrían tenido ventanas de frescura distintas — no sobrevivió a la verificación: todos llevaban exactamente la misma cabecera, al segundo.

Este texto se escribió por tanto en colaboración con una inteligencia artificial, y no lleva cofirma máquina. Las dos cosas van juntas: lo útil para un lector es saber cómo se ha fabricado un texto — lo anterior lo dice — no leer el nombre de una herramienta junto al de alguien que puede responder de él.
