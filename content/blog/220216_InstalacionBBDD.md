Title: Instalación y acceso remoto de bases de datos
Date: 2022-02-16 15:55
Category: Administración de Bases de Datos
lang: es
tags: Oracle,MariaDB,PostgreSQL,MongoDB
Header_Cover: images/covers/database.png
summary: En este artículo se documenta la instalación y el acceso remoto de Oracle, MariaDB, PostgreSQL y MongoDB.

En este artículo vamos a instalar Oracle 19c, MariaDB, PostgreSQL y MongoDB en Debian, y una vez instalados, configuraremos dichos gestores de bases de datos para que podamos acceder de forma remota. Instalaremos Oracle en Centos 8, y el resto de gestores, en Debian.

##<img src="{static}/images/BaseDatos/icono_oracle.png" alt="Una nubecita" width="100"/> Oracle 19c

En primer lugar, bajamos el archivo rpm de Oracle 19c desde su [página oficial](https://www.oracle.com/es/database/technologies/oracle19c-linux-downloads.html). Antes de instalarlo, hay que descargar las dependencias del paquete:
```
curl -o oracle-database-preinstall-19c-1.0-2.el8.x86_64.rpm https://yum.oracle.com/repo/OracleLinux/OL8/appstream/x86_64/getPackage/oracle-database-preinstall-19c-1.0-2.el8.x86_64.rpm
yum -y localinstall oracle-database-preinstall-19c-1.0-2.el8.x86_64.rpm
```

Posteriormente, instalamos el paquete rpm:
```
rpm -Uhv oracle-database-ee-19c-1.0-1.x86_64.rpm
```

Finalizada la instalación, podemos abrir el fichero de configuración (`/etc/sysconfig/oracledb_ORCLCDB-19c.conf`) y cambiar los parámetros que consideremos. En mi caso, he dejado la configuración tal y como viene por defecto:
```
#This is a configuration file to setup the Oracle Database.
#It is used when running '/etc/init.d/oracledb_ORCLCDB configure'.
#Please use this file to modify the default listener port and the
#Oracle data location.
# LISTENER_PORT: Database listener
# El servidor estará a la escucha de los clientes a través de este puerto
LISTENER_PORT=1521
# ORACLE_DATA_LOCATION: Database oradata location
# En esta ruta se guardarán las bases de datos de Oracle
ORACLE_DATA_LOCATION=/opt/oracle/oradata
# EM_EXPRESS_PORT: Oracle EM Express listener
EM_EXPRESS_PORT=5500
```

Después de editar el fichero de configuración, generamos la base de datos de prueba, ORCLCDB:
```
/etc/init.d/oracledb_ORCLCDB-19c configure
```

Ahora podemos empezar a utilizar tanto la base de datos de prueba como los binarios. Como estos últimos se encuentran en `/opt/oracle/product/19c/dbhome_1/bin/`, para no tener que escribir la ruta cada vez que ejecutemos uno, añadiremos las variables necesarias en el fichero `.bash_profile`. Empezamos por conectarnos con el usuario oracle (después de cambiarle la contraseña con `passwd`) y editar dicho archivo:
```
su oracle
nano ~/.bash_profile
```

Dentro, establecemos unos permisos predeterminados para el usuario oracle (todos los ficheros y directorios que cree tendrán, por defecto, los permisos 644). Asimismo, creamos variables de entorno para la base de datos de prueba, el nombre de la misma, la ruta de los binarios y un nuevo valor a la variable $PATH, para que busque los comandos en dicho directorio:
```
if [ -f ~/.bashrc ]; then
. ~/.bashrc
fi

umask 022
export ORACLE_SID=ORCLCDB
export ORACLE_BASE=/opt/oracle/oradata
export ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
export PATH=$PATH:$ORACLE_HOME/bin
```

Guardamos el fichero y volvemos a leerlo con el comando `source` para que se cargue en memoria:
```
source ~/.bash_profile
```

Accedemos a Oracle con el usuario sysdba, con el que tendremos los privilegios para ejecutar determinadas acciones:
```
sqlplus / as sysdba
```

Introducimos la siguiente consulta para comprobar que la base de datos está montada y funcionaadecuadamente:
```
SELECT instance_name, host_name, version, startup_time FROM v$instance;
```

El resultado debería ser el siguiente (nombre de la base de datos, el nombre de la máquina en la que se está ejecutando, la versión de Oracle y la fecha de arranque):
```
INSTANCE_NAME
----------------
HOST_NAME
----------------------------------------------------------------
VERSION		STARTUP_
----------------- --------
ORCLCDB
localhost.localdomain
19.0.0.0.0	03/10/21
```

¿En lugar de eso te devuelve un error y te avisa de que Oracle no está disponible?

<img src="{static}/images/silencio.png" alt="No temas" width="150"/> Que no cunda el pánico.

Seguramente la base de datos no está iniciada, de modo que ejecutamos el comando `startup`. Una vez solucionado, creamos un usuario común (usuario que podrá realizar acciones tanto en la base de datos contenedora como en las bases de datos "enchufables" que se creen en adelante), y le damos todos los privilegios:
```
create user c##usuariolara IDENTIFIED BY lara;
GRANT ALL PRIVILEGES TO c##usuariolara;
```

**Cuidado: por seguridad, en la realidad no es recomendable darle todos los privilegios al usuario.**

<center>
<img src="{static}/images/cuidao.gif" alt="Seamos cautos" width="300"/>
</center>

Finalmente, nos desconectamos de sysdba y entramos como el usuario que acabamos de crear,
tras lo cual podemos comenzar a crear tablas (yo he introducido las tablas de [esta página](https://pastebin.com/Q7b1xW07)):
```
DISCONNECT
CONNECT c##usuariolara
```

Cuando terminemos de insertar tablas y registros, nos dirigimos al fichero `$ORACLE_HOME/network/admin/listener.ora` y cambiamos `localhost` por la IP del servidor. Lo mismo hacemos en el fichero `tnsnames.ora`. A continuación, iniciamos el listener de oracle:
```
lsnr start
```

Al ejecutar `netstat -tln`, debería aparecer una línea con la IP especificada en el fichero `listener.ora`, seguida del puerto 1521 y en modo escucha ("LISTEN").
```
[oracle@localhost lpruna]$ netstat -tln
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address 	 Foreign Address	 	State
tcp	 0	 0  0.0.0.0:111		 0.0.0.0:*	        	LISTEN
tcp      0       0  192.168.122.52:1521  0.0.0.0:*			LISTEN
tcp	 0	 0  0.0.0.0:22		 0.0.0.0:*			LISTEN
tcp6	 0	 0  :::111		 :::*				LISTEN
tcp6	 0	 0  :::22		 :::*				LISTEN
tcp6	 0	 0  :::16029		 :::*				LISTEN
```

Además, con el comando `lsnr status` veremos que la base de datos de prueba “ORCLCDB” se
encuentra activa y en modo escucha.
```
[oracle@localhost lpruna]$ lsnrctl status

LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 09-OCT-2021 15:57:39

Copyright (c) 1991, 2019, Oracle. All rights reserved.
Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.168.122.52)
(PORT=1521)))

STATUS of the LISTENER
------------------------
Alias			 LISTENER
Version			 TNSLSNR for Linux: Version 19.0.0.0.0 - Production
Start Date		 09-OCT-2021 15:55:53
Uptime			 0 days 0 hr. 1 min. 45 sec
Trace Level		 off
Security		 ON: Local OS Authentication
SNMP			 OFF
Listener		 Parameter		 File /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora
Listener		 Log			 File /opt/oracle/diag/tnslsnr/localhost/listener/alert/log.xml
Listening Endpoints Summary...
(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=192.168.122.52)(PORT=1521)))
(DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1521)))
Services Summary...
Service "${ORACLE_SID}" has 1 instance(s).
Instance "${ORACLE_SID}", status UNKNOWN, has 1 handler(s) for this service...
The command completed successfully

[oracle@localhost lpruna]$ echo $ORACLE_SID
ORCLCDB
```

Entramos en la base de datos una vez más y cambiamos los parámetros de la base de datos:
```
SQL> alter system set LOCAL_LISTENER='(ADDRESS=(PROTOCOL=TCP)(HOST=192.168.122.52)(PORT=1521))' SCOPE=BOTH;
```

Por último, si no lo hemos hecho ya, nos conectamos como root y deshabilitamos el cortafuegos que viene preinstalado en Centos 8, para que el cliente pueda acceder de forma remota:
```
systemctl stop firewalld
systemctl disable firewalld
```

En la máquina cliente, nos conectamos a la base de datos especificando el usuario, la IP del
servidor, el puerto y el nombre del servicio:
```
sqlplus c##usuariolara@192.168.122.179:1521/ORCLCDB
```

Esta es la forma más sencilla de acceder de manera remota al servidor de Oracle. Existe otro procedimiento un poco más complejo, pero más cómodo a la larga, y es editar el fichero tnsnames.ora, que se encuentra en el directorio `$ORACLE_HOME/network/admin`. Dentro de dicho de fichero añadiríamos un bloque como el siguiente:
```
Nombre_de_instancia = 
 (DESCRIPTION = 
   (ADDRESS = (PROTOCOL = [protocolo])(HOST = [IP o dominio del servidor que escucha])(PORT = [puerto desde el que escuchará]))
   (CONNECT_DATA = 
     (SERVICE_NAME = [servicio al que queremos acceder])))
```

En este caso, indicaríamos la IP pública y el puerto del servidor (1521 por defecto), desde los cuales escuchará las peticiones de conexión, y especificaríamos al final el servicio de la base de datos de prueba, para que conecte a los clientes a la misma:
```
REMOTO = 
 (DESCRIPTION = 
   (ADDRESS = (PROTOCOL = tcp)(HOST = 192.168.122.179)(PORT = 1521))
   (CONNECT_DATA = 
     (SERVER = DEDICATED)
     (SERVICE_NAME = ORCLCDB))) 
```

Desde el cliente realizaríamos la conexión de la siguiente manera:
```
sqlplus c##usuariolara@192.168.122.179/REMOTO
```

Ya tendríamos acceso al servidor desde un cliente remoto. Solo me queda contaros una cosa más, que os puede facilitar muchísimo la vida si vais a trabajar con cierta frecuencia con Oracle. Os daréis cuenta de que, una vez dentro de la consola de Oracle, no podéis moveros libremente por la línea de comandos ni acceder al historial.

<img src="{static}/images/guiño.jpg" alt="No temáis, Lara está aquí" width="250"/> Pues eso tiene fácil solución.

Instalamos el repositorio EPEL y el paquete rlwrap de dicho repositorio:
```
dnf install epel-release
dnf install rlwrap
```

Después, añadimos las siguientes líneas en el fichero `.bash_profile` del usuario de oracle:
```
alias rlsqlplus='rlwrap sqlplus'
```

A partir de ahora, si entramos en la consola con el comando `rlsqlplus` o `rlwrap sqlplus`, podremos editar la línea que estemos escribiendo y acceder a comandos anteriormente ejecutados.

<center>
<img src="{static}/images/de_nada.gif" alt="Qué puedo decir salvo de nada" width="300"/>
</center>

</br>

##<img src="{static}/images/BaseDatos/mariadb_icono.png" alt="Una foquita" width="100"/> MariaDB

Para empezar, actualizamos el sistema e instalamos el servidor de mariadb como cualquier paquete .deb:
```
sudo apt update
sudo apt install mariadb-server
```

Accedemos al fichero de configuración de mariadb (`/etc/mysql/mariadb.conf.d/50-server.cnf`) y comentamos la línea de “bind-address” para poder conectarnos desde fuera:
```
# bind-address = 127.0.0.1
```

O bien, ponemos la IP 0.0.0.0:
```
bind-address = 0.0.0.0
```

Como hemos modificado la configuración, reiniciamos el servicio de mariadb:
```
sudo service mariadb restart
```

Entramos en el gestor de base de datos como root, creamos una base de datos y le damos privilegios a nuestro usuario remoto:
```
sudo mysql -u root -p
SQL> GRANT ALL PRIVILEGES ON *.* TO 'lara'@'10.0.0.40' IDENTIFIED BY 'lara';
```

Creamos una base de datos de prueba y lo poblamos. Finalmente, nos vamos a otra máquina en la misma red e instalamos el cliente de mariadb:
```
sudo apt install mariadb-client
```

Ahora podemos acceder al servidor especificando la IP del servidor y nuestro usuario en la base de datos:
```
mysql -h 10.0.0.20 -u lara -p
```

* **-h**: host
* **-u**: usuario
* **-p**: nos pide la contraseña si no se lo especificamos nosotros (si es así, escribimos la contraseña pegada al parámetro -p).

</br>

##<img src="{static}/images/BaseDatos/postgresql_icono.png" alt="Un elefantito" width="100"/> PostgreSQL

Primero actualizamos el sistema, instalamos postgresql como cualquier paquete .deb e iniciamos el servidor de base de datos:
```
sudo apt update
sudo apt install postgresql
```

Comprobamos si el servicio se encuentra activo:
```
sudo systemctl status postgresql
```

```
 ● postgresql.service - PostgreSQL RDBMS
	Loaded: loaded (/lib/systemd/system/postgresql.service; enabled; vendor preset: >
	Active: active (exited) since Mon 2021-10-04 16:14:50 UTC; 12min ago
	Main PID: 15812 (code=exited, status=0/SUCCESS)
	Tasks: 0 (limit: 528)
	Memory: 0B
	CPU: 0
	CGroup: /system.slice/postgresql.service

	Oct 04 16:14:50 postgresql systemd[1]: Starting PostgreSQL RDBMS...
	Oct 04 16:14:50 postgresql systemd[1]: Finished PostgreSQL RDBMS.
```

Si es así, le cambiamos la contraseña al usuario "postgres", nos conectamos con el mismo y creamos un nuevo usuario, al que le asignaremos privilegios de superusuario:
```
sudo passwd postgres
su postgres
createuser -s lara -P
```

Ahora podemos crear una base de datos, al que accederemos posteriormente con el usuario remoto:
```
createdb prueba
psql prueba
```

Y procedemos a crear tablas y realizar inserciones. Cuando terminemos, nos dirigimos al fichero de configuración:
```
sudo nano /etc/postgresql/13/main/postgresql.conf
```

En la siguiente línea cambiamos `localhost` por `*` para que el servidor escuche a cualquier
máquina externa que intente conectarse:
```
listen_addresses = ‘*’
```

A continuación, entramos en el fichero `pg_hba.conf`:
```
sudo nano /etc/postgresql/13/main/pg_hba.conf
```

Y cambiamos la dirección IP en la siguiente línea:
```
host	all	all	0.0.0.0/0	md5
```

Reiniciamos el servicio de postgresql:
```
sudo service postgresql restart
```

Vamos a la máquina cliente, instalamos el cliente de postgresql y tratamos de entrar en la base de datos que hemos creado en el servidor (agregamos la IP y el puerto del servidor, el usuario que hemos creado y la base de datos a la que queremos conectarnos):
```
sudo apt install postgresql-client
psql -h 10.0.0.30 -p 5432 -U lara -d prueba
```

</br>

##<img src="{static}/images/BaseDatos/mongodb_icono.png" alt="Una hojita" width="100"/> MongoDB

El primer paso será actualizar el sistema e instalamos el paquete gnupg que necesitaremos para montar nuestro servidor de MongoDB:
```
sudo apt update
sudo apt install -y gnupg
```

Puesto que MongoDB no se encuentra en la paquetería de Debian, tendremos que añadir el repositorio oficial de este. Para ello, nos descargamos la clave pública de MongoDB:
```
wget https://www.mongodb.org/static/pgp/server-4.4.asc -qO- | sudo apt-key add -
```

En siguiente lugar, creamos el fichero de repositorios:
```
sudo nano /etc/apt/sources.list.d/mongodb-org.list
```

Y le añadimos la siguiente línea:
```
deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main
```

Ahora que tenemos un nuevo repositorio, actualizamos la lista de paquetes e instalamos el paquete mongodb-org:
```
sudo apt update
sudo apt install -y mongodb-org
```

Habilitamos el servicio de MondoDB y comprobamos si se ha activado:
```
sudo systemctl enable --now mongod
sudo systemctl status mongod
```

```
 ● mongod.service - MongoDB Database Server
	Loaded: loaded (/lib/systemd/system/mongod.service; enabled; vendor preset: enab>
	Active: active (running) since Mon 2021-10-04 17:58:23 UTC; 4min 5s ago
	Docs: https://docs.mongodb.org/manual
	Main PID: 16056 (mongod)
	Memory: 99.0M
	CPU: 3.541s
	CGroup: /system.slice/mongod.service
	└─16056 /usr/bin/mongod --config /etc/mongod.conf

	Oct 04 17:58:23 mongodb systemd[1]: Started MongoDB Database Server.
```

Al ejecutar el cliente mongo, comprobamos la conexión con los servidores:
```
  MongoDB shell version v4.4.9
  connecting to: mongodb://127.0.0.1:27017/?compressors=disabled&gssapiServiceName=mongodb
  Implicit session: session { "id" : UUID("3e618527-b5b0-4d7b-a4e7-92b80dcd5603") }
  MongoDB server version: 4.4.9
  Welcome to the MongoDB shell.
  For interactive help, type "help".
  For more comprehensive documentation, see
	https://docs.mongodb.com/
  Questions? Try the MongoDB Developer Community Forums
	https://community.mongodb.com
---
  The server generated these startup warnings when booting:
	2021-10-04T17:58:23.381+00:00: Using the XFS filesystem is strongly recommended with the WiredTiger storage engine. See http://dochub.mongodb.org/core/prodnotes-filesystem
	2021-10-04T17:58:24.068+00:00: Access control is not enabled for the database. Read and write access to data and configuration is unrestricted
---
---
	Enable MongoDB's free cloud-based monitoring service, which will then receive and display metrics about your deployment (disk utilization, CPU, operation statistics, etc).


	The monitoring data will be available on a MongoDB website with a unique URL accessible to you and anyone you share the URL with. MongoDB may use this information to make product improvements and to suggest MongoDB products and deployment options to you.


	To enable free monitoring, run the following command:
db.enableFreeMonitoring()
	To permanently disable this reminder, run the following command:
db.disableFreeMonitoring()
---
```

Entramos en la base de datos del administrador y creamos un usuario con privilegios de root:
```
> use admin
switched to db admin
> db.createUser({user: "lara", pwd: "******", roles: [{role: "root", db: "admin"}]})
Successfully added user: {
	"user" : "lara",
	"roles" : [
		{
			"role" : "root",
			"db" : "admin"
		}
	]
}
```

Salimos con `exit`. Ahora podemos entrar con nuestro nuevo usuario con el parámetro -u:
```
mongo -u lara
```

Por último, accedemos al fichero de configuración de MongoDB:
```
sudo nano /etc/mongod.conf
```

Para securizar nuestra base de datos editaremos la siguiente sección:
```
security:
  authorization: enabled
```

Para poder acceder remotamente, debemos cambiar el valor del campo “bindIP”, dejando que cualquier IP (0.0.0.0) pueda acceder en lugar de solo el localhost:
```
net:
  port: 27017
  bindIp: 0.0.0.0
```

Guardamos el fichero y reiniciamos el servicio:
```
sudo systemctl restart mongod
```

Finalmente, podremos acceder al servidor desde la máquina cliente especificando el nombre dela máquina donde se encuentra el servidor, o la dirección IP, y el usuario que hemos creado:
```
mongo --host mongodb -u lara
```

!Espero que este artículo os haya ayudado!

<img src="{static}/images/gracias.png" alt="Gracias por leerme" width="150"/>
