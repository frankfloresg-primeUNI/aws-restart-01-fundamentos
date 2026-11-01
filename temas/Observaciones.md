**30/10/2026**

Para que la instancia ec2 sea pública se tuvo que crear una regla de seguridad con protocolo HHTP y puerto 80. Así mismo, tuve que eliminar la regla de seguridad con protocolo SSH (protocolo 22), para no brindar acceso administrativo.

El navegador obligó a usar https y por ello no estaba cargando la página

**us-east-2 es la región** y **us-east-2a es la zona de disponibilidad** (un datacenter dentro de la región)


**1/11/2026**

Los archivos de windows usan el salto de línea CRLF y los scripts de bash usan LF. Por ello, cuando haga scripts en VSCode tengo que seleccionar LF.

Es importante colocar wait luego de eliminar la instancia, para posteriormente no haya problemas al querer borrar el security group.

Los if hacen los script idempotentes, es decir que se ejecuten dos veces sin que falle

Es importante no colocar comillas a #INSTANCE_IDS, para que la consola tenga dos instancias que borrar y no lo tome como un solo argumento
