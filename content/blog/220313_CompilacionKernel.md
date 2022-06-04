Title: Compilación de un kérnel a medida
Date: 2021-10-26 14:46
Category: Administración de Sistemas Operativos
lang: es
tags: Kernel,Compilación
Header_Cover: images/covers/kernel.jpg
summary: En este artículo vamos a descargar el código fuente de un kernel, configurarlo y compilarlo, hasta que termine siendo completamente funcional y minimalista.

El kernel o núcleo es la parte del sistema encargada de **concederle al software acceso al hardware**, con el fin de administrar de forma segura los recursos del hardware. En otras palabras, el kernel se encarga de hacer que todo funcione correctamente, desde el propio arranque del sistema hasta los diferentes periféricos que tengamos conectados.

<center>
<img src="{static}/images/reparto.gif" alt="Repartiendo permisos" width="400"/>
</center>

Dicho esto, es posible personalizar el núcleo a nuestro gusto, ya sea porque necesitemos habilitar o deshabilitar opciones específicas que no vienen por defecto, o porque simplemente queramos ver cómo administrar nuestro kérnel los diferentes accesos. Para ello, necesitaremos descargarnos el **código fuente** del kérnel, modificarlo según nuestras necesidades y compilarlo. En este caso práctico, compilaremos un kérnel de Linux en Debian 11 Bullseye.

<br>

## Compilación de un kérnel

En primer lugar, para mantener un cierto orden, lo primero que hacemos es crear un directorio donde descargaremos el kérnel:

```bash
mkdir compkernel && cd compkernel
```

A continuación, instalaremos el paquete build-essential, con el que tendremos las herramientas de compilación, así como "qtbase5-dev", una aplicación con entorno gráfico con el que podremos seleccionar los componentes del kernel:

```bash
apt install build-essential qtbase5-dev
```

Una vez instalada la paquetería previa, nos descargamos el código fuente del kérnel. Tras asegurarnos de tener el repositorio *backports* activo en nuestro fichero sources.list, ejecutamos el siguiente comando para ver las versiones disponibles del paquete:

```bash
~/compkernel$ apt policy linux-source
linux-source:
  Instalados: (ninguno)
  Candidato:  5.10.70-1
  Tabla de versión:
     5.14.9-2~bpo11+1 100
        100 http://deb.debian.org/debian bullseye-backports/main amd64 Packages
     5.10.70-1 500
        500 http://deb.debian.org/debian bullseye/main amd64 Packages
     5.10.46-5 500
        500 http://security.debian.org/debian-security bullseye-security/main amd64 Packages
```

Instalamos la versión del *backports*:

```bash
apt install linux-source=5.14.9-2~bpo11+1
```

Al hacer un `ls -l`, comprobamos que se ha descargado el archivo comprimido, así que lo extraemos con `tar`:

```bash
~/compkernel$ tar -xf linux-5.14.13.tar.xz && cd linux-5.14.13
```

Al entrar en el directorio extraído, veremos el fichero mágico Makefile, que contiene todos los hechizos necesarios para realizar la compilación. Además, contamos con un conjuro de ayuda, `make help`, que nos muestra todas las acciones que podemos realizar con el comando `make`.

<center>
<img src="{static}/images/magic_book.gif" alt="El libro mágico de compilación" width="400"/>
</center>

Para compilar el kernel, necesitamos el fichero .config, en el que se especifican los módulos que se van a enlazar **estática** (se cargarán en memoria de forma permanente) o **dinámicamente** (se cargarán en memoria solo cuando se necesite) y los que **no** se van a enlazar (no se cargarán en memoria). Para generar este fichero, tomaremos como base la actual configuración de nuestro kérnel, mediante el siguiente comando:

```bash
make oldconfig
```

Al ejecutar el comando, el sistema nos preguntará si queremos incluir determinados componentes opcionales. Como en esta práctica queremos configurar un kernel lo más minimalista posible, yo he respondido a todo que no. Al final, si listamos el contenido del directorio actual filtrando por `.config`, veremos que por fin se nos ha generado:

```bash
~/compkernel/linux-5.14.13$ ls -la | egrep '.config'
-rw-r--r--   1 debian debian     59 oct 17 10:44 .cocciconfig
-rw-r--r--   1 debian debian 241164 oct 19 17:41 .config
-rw-r--r--   1 debian debian    555 oct 17 10:44 Kconfig
```

Ahora podemos ver cuántos módulos se han enlazado estáticamente (y) y cuántos dinámicamente (m):

```bash
~/compkernel/linux-5.14.13$ egrep '=y' .config | wc -l
2187
~/compkernel/linux-5.14.13$ egrep '=m' .config | wc -l
3722
```

A partir de ahora es cuando podemos ir descartando componentes. Ya que tenemos más de 5000 módulos enlazados, para acortar la carga de trabajo emplearemos el siguiente comando, con el que se descartarán todos aquellos módulos que no están activos (y por tanto, podemos prescindir de ellos):

```bash
make localmodconfig
```

Esta vez nos volverán a preguntar si queremos activar algunos módulos. Una vez más, he respondido que no. Cuando volvemos a contar el número de módulos estáticos y dinámicos enlazados, comprobamos que ya hay menos de 2000:

```bash
~/compkernel/linux-5.14.13$ egrep '=y' .config | wc -l
1509
~/compkernel/linux-5.14.13$ egrep '=m' .config | wc -l
99
```

Finalmente, ahora que no tenemos más que los módulos que estamos utilizando, podemos realizar la compilación. Especificamos con `-j nproc` que genere el número de hilos que existan en nuestro procesador:

```bash
~/compkernel/linux-5.14.13$ make -j4 bindeb-pkg
  SYNC    include/config/auto.conf.cmd
  UPD     include/config/kernel.release
sh ./scripts/package/mkdebian
dpkg-buildpackage -r"fakeroot -u" -a$(cat debian/arch)  -b -nc -uc
dpkg-buildpackage: información: paquete fuente linux-upstream
dpkg-buildpackage: información: versión de las fuentes 5.14.13-1
dpkg-buildpackage: información: distribución de las fuentes bullseye
dpkg-buildpackage: información: fuentes modificadas por debian <debian@debian>
dpkg-buildpackage: información: arquitectura del sistema amd64
 dpkg-source --before-build .
dpkg-checkbuilddeps: fallo: Unmet build dependencies: rsync libelf-dev:native libssl-dev:native
dpkg-buildpackage: aviso: Las dependencias y conflictos de construcción no están satisfechas, interrumpiendo
dpkg-buildpackage: aviso: (Use la opción «-d» para anularlo.)
make[1]: *** [scripts/Makefile.package:83: bindeb-pkg] Error 3
make: *** [Makefile:1576: bindeb-pkg] Error 2
```

<img src="{static}/images/miedo.png" alt="El libro mágico de compilación" width="100"/> Al ejecutar el comando, nos ha dado un error: nos faltan tres dependencias.

No hay problema, las instalamos con `apt`:

```bash
sudo apt install rsync libelf-dev libssl-dev
```

Finalizada la instalación, volvemos a ejecutar el comando anterior, y esta vez no habrá errores...

```bash
BTF: .tmp_vmlinux.btf: pahole (pahole) is not available
Failed to generate BTF for vmlinux
Try to disable CONFIG_DEBUG_INFO_BTF
make[3]: *** [Makefile:1183: vmlinux] Error 1
make[2]: *** [debian/rules:7: build-arch] Error 2
dpkg-buildpackage: fallo: debian/rules binary subprocess returned exit status 2
make[1]: *** [scripts/Makefile.package:83: bindeb-pkg] Error 2
make: *** [Makefile:1576: bindeb-pkg] Error 2
```

<center>
<img src="{static}/images/lluvia.png" alt="Un error más" width="200"/>
</center>

Tal y como nos recomiendan, deshabilitaremos el parámetro `CONFIG_DEBUG_INFO_BTF` comentándolo en el fichero .config:

<center>
<img src="{static}/images/kernel/config_debug.png" alt="CONFIG_DEBUG_INFO_BTF" width="500"/>
</center>

Volvemos a ejecutar el comando, y al final veremos que se ha creado un paquete .deb:

<center>
<img src="{static}/images/kernel/paquete_deb.png" alt="Paquete .deb" width="700"/>
</center>

La instalamos con `dpkg`:

```bash
dpkg -i ../linux-image-5.14.13_5.14.13-2_amd64.deb
```

Comprobamos que está instalado ejecutando el comando `dpkg -l | egrep 'linux-image'` y reiniciamos el ordenador. En el gestor de arranque del GRUB, accedemos a "Opciones avanzadas" e indicamos que queremos arrancar con el nuevo kernel que hemos compilado (5.14).

A continuación, antes de volver a hacer un compilado del kernel, limpiamos los ficheros objeto:

```bash
make clean
```

Y deshabilitamos el resto de módulos que no necesitemos a mano a través de un entorno gráfico:

```bash
make xconfig
```

<center>
<img src="{static}/images/kernel/xconfig.png" alt="Gestión de los módulos del kernel por UI" width="700"/>
</center>

Tened en cuenta que los ***ticks* (✓)** significan que son estáticos, y los **puntos (·)**, dinámicos. Cuando acabemos de configurar el kernel, guardamos el fichero, volvemos a compilarlo con el comando de antes e instalamos con `dpkg` el archivo .deb generado:

```bash
make -j4 bindeb-pkg
sudo dpkg -i ../linux-image-5.14.13_5.14.13-22_amd64.deb
```

Reiniciamos el sistema y entramos con el kernel minimalista. Al filtrar el número de módulos estáticos y dinámicos, en mi sistema solo han quedado 635 estáticos.

<center>
<img src="{static}/images/kernel/modulos.png" alt="El mínimo de módulos" width="700"/>
</center>