PkgBuilder
==========

¿Qué es PkgBuilder?
-------------------

Es una implementación de un sistema de _ports_ al estilo *Gentoo* para Slackware. Permite automatizar la creación de paquetes a partir del código fuente.

Obtiene el código fuente desde la web ofical del desarrolador, verifica la
integridad de los archivos descagados, descomprime los archivos y les aplica
los parches necesarios. Finalmente compila y genera el paquete. 

Los paquetes se generan utiliza *fakeroot* y posteriormente con la aplicación 
oficial de Slackware, _makepkg_, se genera el archivo tgz.

Todo esto está gobernado por unos sencillos archivos *.build* escritos en shell 
script. Estos archivos definen las variables y los métodos necesarios para la
construcción del paquete. PkgBuilder proporciona una estructura jerarquica que
permite heredar el comportamiento comun y repetitivo a partir de otros .build.

¿Por qué PkgBuilder?
--------------------

Los motivos por los que nace PkgBuilder son varios, pero el principal es la 
escasez de paquete oficiales que existen en Slackware, multitud de paquetes que
no se incluyen en la distribución oficial de Slackware, tan basicos como pueden
ser gkrellm, wine o postfix. 

Buscando solucionar estos intenté migrar a otras distribuciones GNU/Linux o 
incluso a otros sistemas operativos libre como NetBSD, pero no encontré nada 
que se ajustara a lo que buscaba. Lo que buscaba era un sistema que me 
permitiera crear paquetes para Slackware a partir de los fuentes sin tenerme 
que preocupar de nada salvo ejecutar unos sencillos comandos, que resolviera 
automáticamente dependencia y que compilara los paquetes optimizados para mi 
sistema. Asi que me puse manos a la obra.


