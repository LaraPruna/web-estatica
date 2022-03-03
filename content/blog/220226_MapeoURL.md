Title: Mapear URL a ubicaciones de un sistema de ficheros
Date: 2021-10-21 16:17
Category: Servicios de Red e Internet
lang: es
tags: HTTP,URL,Mapeo,Apache
Header_Cover: images/covers/url.jpg
summary: En este artículo emplearemos diferentes recursos de Apache para mapear direcciones URL a ubicaciones de un sistema de ficheros.

En este artículo vamos a utilizar diferentes recursos de Apache para **mapear** direcciones URL a ubicaciones de un sistema de ficheros, es decir, crear rutas hacia ficheros del sistema externos a nuestra aplicación web. Para ello, crearemos un host virtual al que accederemos con el dominio `www.mapeo.com` y cuyo directorio raíz estará en `/srv/mapeo`.

<center>
<img src="{static}/images/vespa.gif" alt="Marchamos hacia la zona apache" width="200"/> ¡Rumbo a la zona apache!
</center>

</br>

## Directorio raíz en /srv

En primer lugar, para que nuestra aplicación web pueda ubicarse en dicho directorio, es necesario que editemos el fichero de configuración de Apache (`/etc/apache2/apache2.conf`) y descomentamos las líneas referentes al directorio /srv:
```
<Directory /srv/>
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
```

Después, creamos un fichero de *VirtualHost* en `/etc/apache2/sites-available/` con el siguiente contenido:
```
<VirtualHost *:80>
        ServerName www.mapeo.com
        ServerAdmin webmaster@localhost
        DocumentRoot /srv/mapeo        
        ErrorLog ${APACHE_LOG_DIR}/mapeo.error.log
        CustomLog ${APACHE_LOG_DIR}/mapeo.access.log combined
</VirtualHost>
```

A continuación, creamos el enlace simbólico en `/etc/apache2/sites-enabled/` para activar el *VirtualHost* y recargamos el servicio de apache2:
```
a2ensite mapeo
systemctl reload apache2
```

Añadimos una resolución estática en `/etc/hosts` para que nuestra máquina sepa cómo llegar a la aplicación:
```
172.22.0.77     www.mapeo.com
```

</br>

## Redirección al directorio principal

Vamos a crear la redirección en el fichero del host virtual, de tal manera que los usuarios que intenten acceder al directorio raíz serán redirigidos a la carpeta principal. En otras palabras, cuando se entre a la dirección `www.mapeo.com` se redireccionará automáticamente a `www.mapeo.com/principal`. Añadimos la siguiente línea dentro del *VirtualHost*:
```
RedirectMatch "^/$" "/principal"
```

</br>

## Opciones de denegación

Podemos impedir a los usuarios que vean determinados ficheros o enlaces de la aplicación. En el *VirtualHost*, añadimos el siguiente contenido:
```
<Directory /srv/mapeo/principal>
   Options -Indexes -FollowSymLinks -MultiViews
</Directory>
```

Con esto, conseguimos que los usuarios no puedan ver la lista de ficheros del directorio principal cuando accedan a este, ni seguir los enlaces simbólicos que pueda haber. Con `-MultiViews` no permitimos la negociación de contenido, es decir, que se sirvan diferentes versiones de un mismo documento en el mismo URI.

Para comprobar su funcionamiento, crearemos un enlace simbólico en el directorio principal:
```
touch ~/enlace.txt
ln -s /srv/mapeo/principal/enlace.txt ~/enlace.txt
```

Reiniciamos el servicio de apache2 y comprobamos que no podemos acceder al documento de texto:

<center>
<img src="{static}/images/http/denegacion.png" alt="Acceso denegado" width="500"/>
</center>

</br>

## Listado de fichero y seguimiento de enlaces permitidos

Cuando accedamos a la página `www.mapeo.com/principal/documentos`, queremos que se visualicen los documentos que hay en `/home/usuario/doc`. Por lo tanto, permitiremos el listado de ficheros y el seguimiento de enlaces simbólicos siempre que el propietario del enlace y del fichero al que apunta sean el mismo usuario.

Creamos un directorio en el home llamado docs:
```
mkdir /home/lpruna/docs
```

Entramos en el fichero del *VirtualHost* y añadimos un alias en el directorio principal del servidor:
```
Alias "/principal/documentos" "/home/lpruna/docs/"
```

Habiendo comentado antes las líneas en las que denegábamos estas opciones, reiniciamos el servicio y accedemos a la página `www.mapeo.com/principal/documentos`:

<center>
<img src="{static}/images/http/permitido.png" alt="Acceso permitido" width="500"/>
</center>

</br>

## Redefinición de mensajes de error

En todo el host virtual redefiniremos los mensajes de error de objeto no encontrado y no permitido. Para ello, crearemos dos ficheros html dentro del directorio error. Por otro lado, en el fichero del *VirtualHost* añadiremos las siguientes líneas:
```
ErrorDocument 403 /principal/error/403.html
ErrorDocument 404 /principal/error/404.html
```

Tras reiniciar el servicio de apache, si intentamos acceder a una página que no nos esté permitida, nos aparecerá la página de error 403 que hemos diseñado:

<center>
<img src="{static}/images/http/403.png" alt="Error 403" width="500"/>
</center>

Y si tratamos de ir a una página que no exista, nos aparecerá nuestra página de error 404:

<center>
<img src="{static}/images/http/404.png" alt="Error 404" width="500"/>
</center>