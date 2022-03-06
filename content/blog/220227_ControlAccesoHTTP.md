Title: Control de acceso, autentificación y autorización en Apache
Date: 2021-10-26 15:45
Category: Servicios de Red e Internet
lang: es
tags: HTTP,Autenticacion,Apache
Header_Cover: images/covers/autenticacion.jpeg
summary: En este artículo veremos cómo podemos controlar el acceso de usuarios a diferentes recursos de nuestra aplicación web en Apache.

El **control de acceso** en un servidor web nos permite determinar qué usuarios, y desde dónde, pueden acceder a los recursos del servidor. En Apache encontraremos dos principales tipos de autenticación: la básica y la digest.

Para probarlos, he creado un escenario en Vagrant formado por un **servidor** con una red pública y otra privada, y un **cliente** conectado a la red privada. Este es el contenido del Vagrantfile:
```
Vagrant.configure("2") do |config|

  config.vm.define :nodo1 do |nodo1|
    nodo1.vm.box = "debian/bullseye64"
    nodo1.vm.hostname = "servidor"
    nodo1.vm.synced_folder ".", "/vagrant", disabled: true
    nodo1.vm.network :public_network,
      :dev => "br0",
      :mode => "bridge",
      :type => "bridge"
    nodo1.vm.network :private_network,
      :libvirt__network_name => "muyaislada",
      :libvirt__dhcp_enabled => false,
      :ip => "10.0.0.4",
      :libvirt__forward_mode => "veryisolated"
  end
  config.vm.define :nodo2 do |nodo2|
    nodo2.vm.box = "debian/bullseye64"
    nodo2.vm.hostname = "cliente"
    nodo2.vm.synced_folder ".", "/vagrant", disabled: true
    nodo2.vm.network :private_network,
      :libvirt__network_name => "muyaislada",
      :libvirt__dhcp_enabled => false,
      :ip => "10.0.0.5",
      :libvirt__forward_mode => "veryisolated"
  end
end
```

En el servidor, he generado un **host virtual** con el nombre de dominio `departamentos.iesgn.org`. La página web se compone de dos directorios: `departamentos.iesgn.org/intranet`, al que solo tiene acceso el cliente desde la red privada; y `departamentos.iesgn.org/internet`, al que solo tiene acceso el anfitrión desde la red pública. Así ha quedado el *virtualhost*:
```
<VirtualHost *:80>
	        ServerName departamentos.iesgn.org
	        ServerAdmin webmaster@localhost
	        DocumentRoot /var/www/departamentos
	        ErrorLog ${APACHE_LOG_DIR}/departamentos.error.log
	        CustomLog ${APACHE_LOG_DIR}/departamentos.access.log combined

	<Directory /var/www/departamentos/intranet>
    	<RequireAll>
          Require all granted
          Require not ip 192.168 172.22
        </RequireAll>
	</Directory>

	<Directory /var/www/departamentos/internet>
        <RequireAll>
          Require all granted
          Require not ip 10.0.0
        </RequireAll>
	</Directory>

</VirtualHost>
```

Cuando intentamos acceder desde el anfitrión a Intranet, nos saltará la página de error que he preparado para esta ocación:

<center>
<img src="{static}/images/http/403_intranet.png" alt="No pasarás" width="500"/>
</center>

Pero sí podemos acceder al directorio Internet:

<center>
<img src="{static}/images/http/acceso_internet.png" alt="Hemos accedido a Internet desde una red pública" width="500"/>
</center>

Por otro lado, si entramos desde el cliente al directorio Internet, nos saldrá la página de error 403:

<center>
<img src="{static}/images/http/403_internet.png" alt="No pasarás" width="500"/>
</center>

Pero en cambio sí podemos acceder a la Intranet desde el cliente:

<center>
<img src="{static}/images/http/Acceso_intranet.png" alt="Hemos accedido a la Intranet desde la red privada" width="500"/>
</center>

Dicho esto, comencemos a ver ambas formas de autentificación. <img src="{static}/images/corriendo.png" alt="Empezamos" width="200"/>

</br>

##<img src="{static}/images/http/candado_viejo.jpg" alt="Candado viejo" width="100"/> Autenticación básica

Esta es la forma de autenticación más básica, y se emplea a través de un módulo que ya viene instalado con Apache: [mod_auth_basic](https://httpd.apache.org/docs/2.4/es/mod/mod_auth_basic.html). Con este tipo de autenticación, vamos a limitar el acceso a la URL `departamentos.iesgn.org/secreto`. Para empezar, he creado una carpeta llamada "claves" en el servidor, y dentro he generado el fichero de contraseñas con `htpasswd` y el parámetro -c (de *create*):
```
vagrant@servidor:~$ sudo mkdir /etc/apache2/claves
vagrant@servidor:~$ sudo htpasswd -c /etc/apache2/claves/passwd.txt lara
New password: 
Re-type new password: 
Adding password for user lara
```
<center>
<img src="{static}/images/cuidao.gif" alt="Cuidao" width="200"/> !Ojo cuidao!
</center>

El parámetro -c solo se utiliza con el **primer usuario**. Para introducir el resto de usuarios quitad ese parámetro, o se borrarán los anteriores que hayáis metido.

Si hacemos un `cat` del fichero, vemos que se ha generado un usuario con una contraseña cifrada:
```
lara:$apr1$Yi8ix035$TyDSJxxdA4tpozz3B1oEK1
```

Añadimos el directorio "secreto" en el VirtualHost de la siguiente manera:
```
<Directory /var/www/departamentos/secreto>
        AuthUserFile "/etc/apache2/claves/passwd.txt"
        AuthName "Secreto"
        AuthType Basic
        Require valid-user
</Directory>
```

* En **Directory** especificamos la ruta del directorio en la aplicación que queremos proteger.
* En **[AuthUserFile](https://httpd.apache.org/docs/2.4/es/mod/mod_authn_file.html#authuserfile)** indicamos el fichero que hemos creado antes con los usuarios que pueden acceder y sus respectivas contraseñas.
* En **[AuthName](https://httpd.apache.org/docs/2.4/es/mod/core.html#authname)** indicamos la frase que queremos que aparezca en la ventana emergente que nos pedirá el usuario y la contraseña.
* En **[AuthType](https://httpd.apache.org/docs/2.4/es/mod/mod_authn_core.html#authtype)** indicamos el tipo de autenticación que vamos a emplear (en este caso, la básica).
* Por último, añadimos la línea `Require valid-user` para permitir que acceda todo aquel usuario válido, es decir, que aparezca en el fichero de usuarios que hemos especificado (y que, por supuesto, introduzca la contraseña correcta).

Al intentar acceder nos pedirá un usuario y una contraseña:

<center>
<img src="{static}/images/http/secreto_autenticacion.png" alt="Nos piden usuario y contraseña" width="750"/>
</center>

Pero pero un momento, si echamos un vistazo a las cabeceras de la petición, vemos que las credenciales están codificadas en base64...

<img src="{static}/images/miedo.png" alt="NOOOOO" width="200"/>...y se pueden traducir fácilmente:

<center>
<img src="{static}/images/http/cabecera.png" alt="Credenciales en base64" width="350"/>
<img src="{static}/images/http/base64.png" alt="Credenciales traducidas" width="250"/>
</center>

Tranquilidad, hay una forma de arreglar este problema, y es empleando la otra forma de autentificación.

</br>

##<img src="{static}/images/http/candado_fuerte.jpg" alt="Candado fuerte" width="100"/> Autenticación digest

La autentificación tipo digest soluciona el problema de la transferencia de contraseñas en claro sin necesidad de usar SSL. El módulo de autenticación necesario suele venir con Apache, pero no habilitado por defecto. Para activarlo, usamos la utilidad `a2enmod` y reiniciamos el servicio de Apache:
```
a2enmod auth_digest
systemctl restart apache2
```

El procedimiento es muy similar al de la autenticación básica, pero cambiando algunas de las directivas y usando la utilidad `htdigest` en lugar de `htpassword` para crear el fichero de contraseñas. Además, la directiva *AuthName* la usaremos para identificar un nombre de dominio (*realm*), que deberá coincidir con el que introduzcamos como argumento en el comando `htdigest`:
```
vagrant@servidor:~$ sudo htdigest -c /etc/apache2/claves/digest.txt secreto lara
Adding password for lara in realm secreto.
New password:
Re-type new password:
```

Para mayor seguridad, vamos a crear también un fichero con los grupos a los que permitamos el acceso. Dentro del archivo, añadimos los grupos separados por comas, junto con sus respectivos usuarios, de la siguiente forma:
```
directivos: lara lpruna
```

Finalmente, cambiamos la configuración del directorio en el VirtualHost:
```
<Directory /var/www/departamentos/secreto>
        AuthUserFile "/etc/apache2/claves/digest.txt"
        AuthGroupFile "/etc/apache2/claves/groups.txt"
        AuthName "secreto"
        AuthType Digest
        Require valid-user
        Require group directivos
</Directory>
```

* En el parámetro **AuthUserFile** cambiamos el fichero de contraseñas por la que hemos creado con `htdigest`.
* En **[AuthGroupFile](https://httpd.apache.org/docs/2.4/es/mod/mod_authz_groupfile.html#authgroupfile)** indicamos la ruta del fichero de grupos que hemos creado para limitar el acceso a dichos grupos.
* En **AuthName** indicamos el nombre de dominio que introducimos como argumento a la hora de crear el fichero de contraseñas.
* En **AuthType** cambiamos el tipo básico por Digest.
* Por último, especificamos en la última línea (**Require group**) el grupo o grupos que hayamos incluido en el fichero de grupos.

Una vez hemos terminado de configurar la autenticación digest, reiniciamos el servicio de Apache. Tras crear el grupo "directivos" en el sistema y asignárselo a nuestro usuario, probamos a acceder a la aplicación web:

<center>
<img src="{static}/images/http/AuthDigest.png" alt="Nos piden usuario y contraseña" width="750"/>
</center>

Al echar un vistazo a las cabeceras, comprobamos que ahora el usuario y la contraseña están encriptados:

<center>
<img src="{static}/images/http/digest.png" alt="Nos piden usuario y contraseña" width="750"/>
</center>

</br>

<img src="{static}/images/pensando.png" alt="Pose pensativo" width="150"/> **¿Pero cómo funciona este método de autentificación?**

Cuando intentamos acceder desde el cliente a una URL que emplea el método de autentificación de tipo digest:

Primero, el servidor manda una respuesta del tipo 401 *HTTP/1.1 401 Authorization Required* con una cabecera *WWW-Authenticate* al cliente de la siguiente forma:
```
WWW-Authenticate: Digest realm="secreto", 
                  nonce="cIIDldTpBAA=9b0ce6b8eff03f5ef8b59da45a1ddfca0bc0c485", 
                  algorithm=MD5, 
                  qop="auth"
```

Después, el navegador del cliente muestra una ventana emergente preguntando por el nombre de usuario y contraseña, y cuando se rellena, se envía una petición con una cabecera *Authorization*:
```
Authorization  Digest username="lara", 
                realm="secreto", 
                nonce="cIIDldTpBAA=9b0ce6b8eff03f5ef8b59da45a1ddfca0bc0c485",
                uri="/secreto/", 
                algorithm=MD5, 
                response="814bc0d6644fa1202650e2c404460a21", 
                qop=auth, 
                nc=00000001, 
                cnonce="3da69c14300e446b"
```

La información que se manda es *response*, que en este caso está cifrada usando MD5 y que se calcula de la siguiente manera:

* Se calcula el MD5 del nombre de usuario, del dominio (*realm*) y la contraseña, la llamamos HA1.
* Se calcula el MD5 del método de la petición (por ejemplo, GET) y de la uri a la que estamos accediendo, la llamamos HA2.
* El resultado que se manda es el MD5 de HA1, un número aleatorio (*nonce*), el contador de peticiones (*nc*), el *qop* y el HA2.

Una vez que lo recibe el servidor, puede hacer la misma operación y comprobar si la información que se ha enviado es válida, con lo que se permitiría el acceso.

<center>
<img src="{static}/images/bingo.png" alt="Ýa está claro" width="200"/>
</center>