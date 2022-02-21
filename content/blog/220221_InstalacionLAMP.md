Title: Instalación de un servidor LAMP y phpmyadmin
Date: 2021-10-13 16:55
Category: Implantación de Aplicaciones Web
lang: es
tags: MariaDB,Apache,Debian,PHP
Header_Cover: images/covers/LAMP.png
summary: En este artículo aprenderemos a instalar un LAMP en Debian, además de la aplicación web de MySQL/MariaDB.

LAMP es el acrónimo que forman las siglas de cuatro tecnologías empleadas comúnmente para la implantación de aplicaciones web: el sistema operativo **Linux**, el servidor web **Apache**, la base de datos **MySQL** (o MariaDB), y el lenguaje de programación **PHP** (o Perl o Python).

<center>
<img src="{static}/images/LAMP/acronimo.jpeg" alt="LAMP significa lámpara en inglés." width="400"/>
</center>

En este caso, instalaremos el LAMP con Linux, Apache, MariaDB y PHP para poder desplegar phpmyadmin, la aplicación web de MySQL/MariaDB escrita en PHP que nos permite gestionar nuestra base de datos desde un entorno gráfico. Para ello, necesitaremos instalar dichos paquetes. En el caso de MariaDB, puedes seguir la guía de instalación que desarrollé en este [artículo](https://www.sysraider.es/principal/instalacion-y-acceso-remoto-de-bases-de-datos.html). Una vez instalado el servidor de bases de datos, pasamos a instalar Apache desde los repositorios:
```
apt update && apt install apache2
```

Después, instalamos PHP junto con otros paquetes necesarios para la aplicación:
```
apt install php libapache2-mod-php php-mysql
```

A la hora de hacer peticiones web a los directorios de la aplicación, para que Apache priorice los archivos PHP antes que otros, editamos el fichero “dir.conf”:
```
nano /etc/apache2/mods-enabled/dir.conf
```

Añadimos "index.php" justo después de "DirectoryIndex":
```
<IfModule mod_dir.c>
DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
</IfModule>
```

Al haber cambiado la configuración, reiniciamos el servicio de Apache:
```
systemctl restart apache2
```

<img src="{static}/images/yes.png" alt="Ya estamos preparados" width="150"/> Ya estaríamos listos para desplegar una aplicación web PHP.

Ahora accedemos como root a MariaDB y creamos una base de datos y un usuario con privilegios sobre ella. A continuación, instalamos phpmyadmin desde los repositorios:
```
apt install pypmyadmin
```

Ahora, al acceder al directorio phpmyadmin, nos aparecerá el control de acceso de la aplicación:

<center>
<img src="{static}/images/LAMP/login.png" alt="Inicio de sesión con usuario y contraseña" width="750"/>
</center>

Sin embargo, si listamos el contenido del directorio raíz, no encontraremos ese directorio:

<center>
<img src="{static}/images/LAMP/documentroot.png" alt="Ni rastro del directorio phpmyadmin" width="400"/>
</center>

<img src="{static}/images/pensando.png" alt="Misterio..." width="150"/> ¿Cómo es que entonces podemos acceder a él?

Pues porque la instalación de phpmyadmin ha creado un fichero de configuración en apache2, `/etc/apache2/conf-available/myphpadmin.conf`, que es un enlace simbólico a /etc/phpmyadmin/apache.conf. La primera línea del fichero es:
```
Alias /phpmyadmin /usr/share/phpmyadmin
```

Esta directiva nos permite crear una ruta `phpmyadmin`, donde se nos muestra el contenido de un directorio que se encuentra fuera del directorio raíz, en este caso, `/usr/share/phpmyadmin`. Eso significa que la aplicación está realmente en ese directorio. De hecho, si descomentamos esa línea y reiniciamos el servicio de apache2, ya no podremos acceder.

Para no tener que entrar siempre a través de la dirección IP, podemos crear un *virtualhost* como el siguiente:
```
<VirtualHost *:80>

        ServerName viajes.lara.org
        ServerAdmin webmaster@localhost
        DocumentRoot /usr/share/phpmyadmin
        ErrorLog ${APACHE_LOG_DIR}/viajeslara.error.log
        CustomLog ${APACHE_LOG_DIR}/viajeslara.access.log combined

<Directory /usr/share/phpmyadmin>
    Options SymLinksIfOwnerMatch
    DirectoryIndex index.php

    <IfModule mod_php7.c>
        php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
        php_admin_value open_basedir /usr/share/phpmyadmin/:/usr/share/doc/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/:/usr/share/javascript/
    </IfModule>

</Directory>

<Directory /usr/share/phpmyadmin/templates>
    Require all denied
</Directory>

<Directory /usr/share/phpmyadmin/libraries>
    Require all denied
</Directory>

</VirtualHost>
```

Añadimos una resolución estática en `/etc/hosts` y ya podremos acceder a la aplicación a través de un dominio:

<center>
<img src="{static}/images/LAMP/viajeslara.png" alt="Inicio de sesión" width="750"/>
<img src="{static}/images/LAMP/accesoviajes.png" alt="Gestión gráfica de la base de datos" width="750"/>
</center>