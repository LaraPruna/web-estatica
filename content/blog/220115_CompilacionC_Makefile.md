Title: Compilación de un programa en C utilizando un Makefile
Date: 2021-10-04 19:43
Category: Administración de Sistemas Operativos
lang: es
tags: Compilación,C,Makefile
Header_Cover: images/covers/compilacion.jpg
summary: En este artículo aprenderemos a compilar un programa escrito en C e instalarlo en nuestra máquina.

**En este artículo aprenderemos a compilar un programa escrito en C e ins
talarlo en nuestra máquina.**

A modo de ejemplo, he elegido el programa "parted", que nos permite particionar y redimensionar nuestros discos, así como copiar diversos sistemas de ficheros.

<br>

## Descarga y compilación del paquete

En primer lugar, para descargarnos el código fuente desde Debian, nos conectamos como root y ejecutamos el comando `apt source`:
```
sudo su
apt source parted
```

En el directorio actual, se nos habrá descargado los siguientes cuatro ficheros:
```
root@debian:/home/lpruna/parted# ls -l
total 1888
-rw-r--r--  1 root root   56140 ene 30  2021 parted_3.4-1.debian.tar.xz
-rw-r--r--  1 root root    3145 ene 30  2021 parted_3.4-1.dsc
-rw-r--r--  1 root root 1860300 ene 30  2021 parted_3.4.orig.tar.xz
-rw-r--r--  1 root root     508 ene 30  2021 parted_3.4.orig.tar.xz.asc
```

Descomprimos el archivo con extensión `.orig.tar.xz`:
```
tar -xf parted_3.4.orig.tar.xz
```

Dentro del nuevo directorio, ejecutamos el archivo "configure", con el que comprobaremos que tenemos todas las dependencias instaladas:
```
cd parted-3.4
./configure
```

<img src="{static}/images/alarma.png" alt="¡Ojo!" width="150"/> ¡Ojo! A mí me ha saltado un error en mitad del chequeo.

El sistema me ha informado de que GNU Parted necesita `libuuid` para funcionar, y que podemos encontrarlo en los paquetes libuuid-devel, uuid-dev o similar:
```
configure: error: GNU Parted requires libuuid - a part of the util-linux-ng package (but
usually distributed separately in libuuid-devel, uuid-dev or similar)
This can probably be found on your distribution's CD or FTP site or at:
    http://userweb.kernel.org/~kzak/util-linux-ng/
Note: originally, libuuid was part of the e2fsprogs package.  Later, it
moved to util-linux-ng-2.16, and that package is now the preferred source.
```

Por lo tanto, trataremos de instalar alguno de esos paquetes desde los repositorios:
```
apt install uuid-dev
```

Para asegurarnos de que no falta ninguna otra dependencia, podemos ver la lista completa en el fichero .dsc e instalarlos manualmente con `apt install`:
```
cat parted_3.4-1.dsc

Build-Depends: dpkg-dev (>= 1.15.7~), debhelper (>= 9.20150501~), debhelper-compat (= 9), dh-exec, libncurses-dev | libncurses5-dev, libreadline-dev | libreadline6-dev, libdevmapper-dev (>= 2:1.02.39) [linux-any], uuid-dev, gettext, texinfo (>= 4.2), debianutils (>= 1.13.1), libblkid-dev, pkg-config, check, dh-autoreconf, autoconf (>= 2.64), automake (>= 1:1.11.6), autopoint, gperf
```

<img src="{static}/images/peli.png" alt="¡Método informático!" width="150"/> O BIEN podemos hacerlo de la forma cómoda y rápida. 

Instalamos todas las dependencias con un solo comando:
```
apt build-dep parted
```

Cuando volvemos a ejecutar `configure`, se generará el fichero Makefile, que contiene un conjunto de intrucciones y reglas:
```
configure: creating ./config.status
config.status: creating Makefile
config.status: creating lib/Makefile
config.status: creating include/Makefile
config.status: creating include/parted/Makefile
config.status: creating libparted/Makefile
config.status: creating libparted/labels/Makefile
config.status: creating libparted/fs/Makefile
config.status: creating libparted/tests/Makefile
config.status: creating libparted.pc
config.status: creating libparted-fs-resize.pc
config.status: creating parted/Makefile
config.status: creating partprobe/Makefile
config.status: creating doc/Makefile
config.status: creating doc/C/Makefile
config.status: creating doc/pt_BR/Makefile
config.status: creating debug/Makefile
config.status: creating debug/test/Makefile
config.status: creating tests/Makefile
config.status: creating po/Makefile.in
config.status: creating lib/config.h
config.status: linking ./parted-3.4/GNUmakefile to GNUmakefile
config.status: executing depfiles commands
config.status: executing libtool commands
config.status: executing po-directories commands
config.status: creating po/POTFILES
config.status: creating po/Makefile

Type 'make' to compile parted.
```

Esta vez ha ido todo fluído y sin problemas. Si echamos un vistazo al directorio `./parted`, veremos que tenemos ficheros .c. Al final de la salida del comando, se nos indica que ejecutemos el comando "make" para compilar el programa. Cuando lo hagamos, se escaneará el fichero Makefile y, siguiendo sus instrucciones, compilará el programa creando ficheros .o (ficheros objeto) a partir de los archivos .c.
```
make
```

<img src="{static}/images/cocinando.jpg" alt="30.000 siglos después" width="250"/> Esperamos mientras el programa se cocina a fuego lento.

Finalmente, para instalar el paquete y crear el binario, introducimos el siguiente comando (cuya tarea, por supuesto, también está indicada en el fichero Makefile):
```
make install
```

Con esto, lo que hace el sistema es coger los diferentes objetos, ordenarlos y colocarlos en los directorios que les corresponden. Sin embargo, si ejecutamos un `apt policy` del programa, nos dirá que no existe:
```
$ apt policy parted
parted:
  Installed: (none)
  Candidate: 3.4-1
  Version table:
     3.4-1 500
        500 http://deb.debian.org/debian bullseye/main amd64 Packages
```

Pero en cambio sí que existe la ayuda del comando:
```
$ man -w parted
/usr/local/man/man8/parted.8
```

La razón es que lo único que hemos hecho es ordenar los diferentes ficheros que conforman el programa sin que lo hayamos registrado en la lista de paquetes instalados del sistema. Si quisiéramos desinstalar el paquete, usaríamos la directiva `make uninstall`, y para borrar los ficheros objeto (que, una vez ordenados por el sistema, ya no necesitamos) usamos `make clean`.

<br>

## Creación del paquete .deb a partir de las fuentes

Construimos el paquete .deb con el comando `dpkg-buildpackage`:
```
dpkg-buildpackage -rfakeroot -b -uc -us
```

* -rfakeroot: simula privilegios de root (con lo cual evitamos problemas de permisos).
* -b: compila solo el paquete binario.
* -uc: no firma los archivos .buildinfo y .changes.
* -us: no firma el paquete fuente.

"Instalamos" dicho paquete para que el sistema lo incluya en sus registros:
```
dpkg -i parted_3.4-1_amd64.deb
```

Nos saldrá el siguiente resultado:
```
Selecting previously unselected package parted.
(Reading database ... 34940 files and directories currently installed.)
Preparing to unpack parted_3.4-1_amd64.deb ...
Unpacking parted (3.4-1) ...
dpkg: dependency problems prevent configuration of parted:
 parted depends on libparted2 (= 3.4-1); however:
  Package libparted2 is not installed.

dpkg: error processing package parted (--install):
 dependency problems - leaving unconfigured
Processing triggers for man-db (2.9.4-2) ...
Errors were encountered while processing:
 parted
```

<img src="{static}/images/asombrada.png" alt="Ups" width="150"/>...Ejem, al parecer, falta por resolver una dependencia.

Instalamos la que se nos indica en el mensaje, cuyo paquete .deb se encuentra en el mismo directorio:
```
$ dpkg -i libparted2_3.4-1_amd64.deb 
Selecting previously unselected package libparted2:amd64.
(Reading database ... 34949 files and directories currently installed.)
Preparing to unpack libparted2_3.4-1_amd64.deb ...
Unpacking libparted2:amd64 (3.4-1) ...
Setting up libparted2:amd64 (3.4-1) ...
Processing triggers for libc-bin (2.31-13) ...
```

Y ahora ya podemos instalar el paquete principal de parted:
```
$ dpkg -i parted_3.4-1_amd64.deb 
(Reading database ... 34955 files and directories currently installed.)
Preparing to unpack parted_3.4-1_amd64.deb ...
Unpacking parted (3.4-1) over (3.4-1) ...
Setting up parted (3.4-1) ...
Processing triggers for man-db (2.9.4-2) ...
```

Esta vez, si ejecutamos un `apt policy` de parted, nos aparecerá como instalado:
```
apt policy parted
parted:
  Installed: 3.4-1
  Candidate: 3.4-1
  Version table:
 *** 3.4-1 500
        500 http://deb.debian.org/debian bullseye/main amd64 Packages
        100 /var/lib/dpkg/status
```

<br>

## Enlaces de interés

Sk. (2021, 7 septiembre). How To Build Debian Packages From Source. OSTechNix. <https://ostechnix.com/how-to-build-debian-packages-from-source/>
