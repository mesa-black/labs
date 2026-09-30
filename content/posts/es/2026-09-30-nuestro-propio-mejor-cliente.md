---
title: "Éramos nuestro propio mejor cliente. Era un fallo."
standfirst: "Nuestra empresa publica en nuestra plataforma, y se contaba a sí misma en la facturación, en el embudo y en las listas de seguimiento. Cómo la sacamos de las estadísticas sin sacarla del sitio."
key: notre-propre-meilleur-client
date: 2026-09-30
slug: nuestro-propio-mejor-cliente
---

Todo el mundo recomienda usar el propio producto. Nadie advierte del efecto secundario: en cuanto tu empresa tiene una cuenta, entra en tus cifras. No en una nota al pie, sino en la facturación, en la tasa de conversión, en la lista de clientes a los que hay que llamar.

Nuestro caso: BlackMesa publica casos reales en Show me the REX. La cuenta es real, el plan es real, los artículos se leen. Lo que no es real son los ingresos: no nos facturamos a nosotros mismos. Resultado: un cliente de cero euros figuraba en el MRR, inflaba el reparto por planes y ocupaba una casilla del embudo de conversión sin haber convertido jamás nada.

La corrección evidente — «excluimos nuestra empresa» — es falsa. Da por supuesto que el problema es la empresa. El problema está en otro sitio.

## No es «a quién excluir», es «qué responde esta cifra»

El reflejo es buscar una lista de entidades que apartar. La pregunta correcta se plantea métrica a métrica: ¿de qué pregunta es respuesta esta cifra?

Un contador de visualizaciones responde a «cuánta gente ha leído este texto». La respuesta es la misma venga el lector de nuestras oficinas o de cualquier otro sitio: la página se sirvió, se leyó, el contenido existe. Excluir nuestras visualizaciones volvería falsa esa cifra.

La facturación mensual responde a «cuánto nos pagan nuestros clientes». Nuestra propia empresa no es un cliente. Su presencia vuelve falsa esa cifra.

Ambas métricas miran la misma base de datos, a veces la misma fila, y necesitan reglas opuestas. No es una excepción que gestionar, es la regla: **la unidad de exclusión no es el dato, es la pregunta formulada.**

## El caso que zanja: una visualización que cuenta y no cuenta

El mejor ejemplo es también el más incómodo, porque descarta cualquier atajo de implementación.

En la plataforma, la visualización de un caso alimenta dos cosas distintas. Por un lado la audiencia: el contador que aparece en el artículo, el acumulado del panel, la curva de tráfico. Por otro, una señal comercial: «qué empresas han consultado tus casos», que sirve para identificar contactos con los que retomar el hilo.

Mismo evento, mismo registro. En el primer grupo, una lectura hecha desde nuestras oficinas cuenta: alguien ha leído de verdad. En el segundo no debe contar de ninguna manera: no somos un cliente potencial al que llamar, y un lector interno dentro de una lista de leads es una acción comercial disparada para nada.

No existe, por tanto, un filtro global que se ponga una sola vez en la entrada. Cada consulta tiene que saber a qué familia pertenece.

## Una marca en la base de datos, no una constante en el código

Primera versión, la más rápida: una lista de nombres de empresa escrita en el código. Duró una hora. Una constante obliga a desplegar para reclasificar una empresa y, sobre todo, miente sobre la naturaleza de la información: «esta empresa no es un cliente» es un dato de negocio, cambia, se decide, y tiene que estar a la vista de quien administra las cuentas.

Así que se convirtió en una casilla en la ficha de empresa, con su texto de ayuda explícito, porque una opción cuyo alcance nadie entiende acaba marcada al azar:

> Nuestras propias empresas publican y siguen visibles en el sitio público, pero no cuentan en ningún dato comercial ni de marketing: MRR, planes, embudo, upsell/abandono, leads, resúmenes. Las visualizaciones y las visitas sí se siguen contando.

La lista de nombres no desapareció: sirve de arranque, para que un entorno recién instalado no empiece nunca con cifras contaminadas. Pero ya no decide nada.

El predicado en sí vive en una única clase pequeña, en dos versiones: una para las consultas del ORM y otra para el SQL en crudo. Parece anecdótico; es lo que hace la regla auditable. Encontrar los sitios que la aplican se convirtió en una búsqueda de texto, y contrastarla con la lista de cifras comerciales se hace a ojo en un minuto.

## Verificar en lugar de releer

Releer el propio código de exclusión no demuestra nada: uno relee lo que cree haber escrito. La única verificación que vale consiste en cambiar la casilla y comparar los paneles antes y después, cifra por cifra.

Una treintena de valores se movieron. Siete se quedaron rigurosamente idénticos, y ese era el resultado esperado: son los contadores de audiencia y los volúmenes de contenido publicado. Una cifra que se mueve cuando no debía es un fallo; una cifra que no se mueve cuando debía es un olvido. Sin ese paso no habríamos distinguido ninguno de los dos.

El resultado final: una marca, una clase de política, treinta y cuatro predicados repartidos en ocho archivos — MRR, planes, embudo, upsell, riesgo de abandono, seguimientos, inteligencia comercial, resúmenes mensuales, caducidad de cupones, nurturing.

Este último merece una mención. Sin la exclusión, nuestra propia empresa entraba en la secuencia automática de reactivación. Nos habríamos enviado nuestros propios correos de recuperación.

## Lo que dio de sí

- **Un MRR sin ningún cliente de cero euros dentro**, y una tasa de conversión que ya no cuenta nuestro propio registro en el denominador.
- **Una treintena de valores corregidos** en los paneles comerciales, siete intencionadamente sin cambios.
- **Cero cambios en la parte pública**: los casos siguen publicados, visibles, filtrables, y sus visualizaciones se siguen contando.
- **Una regla escrita en un solo sitio**, con su motivo, en lugar de un `AND` copiado de consulta en consulta.
- **Una casilla** que permite reclasificar una empresa sin desplegar.

## Buenas prácticas

- Clasificar cada métrica antes de programar el filtro: medida de audiencia o señal comercial. La respuesta determina la regla, y no es la misma para dos cifras sacadas de la misma tabla.
- Poner la pertenencia en la base de datos, no en una constante: es un dato de negocio, cambia y se decide.
- Concentrar el predicado en una sola clase aunque quepa en una línea: lo importante no es reutilizarlo, es poder encontrar todas las llamadas.
- Verificar cambiando la casilla: comparar las cifras antes y después es la única forma de distinguir un olvido de una decisión.
- Escribir el alcance en la interfaz de administración, justo donde se marca la casilla.

## Puntos de vigilancia

- **Nada impide que la próxima consulta olvide el predicado.** La regla se sostiene con la revisión de código, no con una prueba automática, y hoy esa es la debilidad principal del montaje.
- Una exclusión demasiado amplia es tan falsa como la ausencia de exclusión: quitar nuestras visualizaciones del contador de audiencia habría producido una mentira en el otro sentido.
- El día en que una empresa interna se convierta en cliente de pago de verdad, habrá que desmarcar la casilla, y nadie lo recordará. Esa decisión es humana y necesita un momento fijado para revisarla.
- Decir públicamente que tus estadísticas excluyen tus propios datos no cuesta nada, y es mejor que descubrirlo en boca de otro.
