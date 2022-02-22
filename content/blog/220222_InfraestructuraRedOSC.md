Title: Infraestructura de red router-nat desde OpenStack Client (OSC)
Date: 2021-10-28 18:07
Category: Implantación de Aplicaciones Web
lang: es
tags: Openstack,CLI,router-nat,Redes
Header_Cover: images/covers/openstack.png
summary: En este artículo montaremos una infraestructura de red router-nat desde el cliente de Openstack en línea de comandos.

Vamos a crear la siguiente infraestructura:

<center>
<img src="{static}/images/Openstack/topologia.png" alt="Esquema de red" width="750"/>
</center>

El esquema de red tendrá las siguientes características:

* Dispondrá de una **red interna** con direccionamiento 192.168.0.0/24, tendrá el DHCP activado, la puerta de enlace será el 192.168.0.1 y el DNS que reparte el 192.168.202.2 (nuestro servidor DNS interno).
* Crearemos una instancia a partir de una imagen, que hará de **router** y estárá conectado a nuestra red y a la red interna en la dirección 192.168.0.1. Esta máquina será la puerta de enlace de la otra máquina.
* También crearemos una instancia a partir de un volumen, que será el **cliente** y que tendrá la IP 192.168.0.100, evidentemente conectada a la red interna.

Una vez descrita la infraestructura, ya podemos ponernos en marcha.

<center>
<img src="{static}/images/vespa.gif" alt="En marcha" width="300"/>
</center>

Lo primero que haremos es crear la red interna:
```
openstack network create red_interna
openstack subnet create --network red_interna --subnet-range 192.168.0.0/24 --dhcp --gateway 192.168.0.1 --dns-nameserver 192.168.202.2 subred_interna.
```

A continuación, creamos una instancia llamada "router" que estará conectada a nuestra red:
```
openstack server create --flavor m1.mini \
--image "Debian 11.0 - Bullseye" \
--key-name clave_lara \
--network "red de lara.pruna" \
router
```

Añadimos una nueva interfaz al router conectada a la red interna con la IP 192.168.0.1.
```
openstack port create --network red_interna --fixed-ip ip-address=192.168.0.1 puerto_router
```

Para añadir el puerto al router, introducimos el siguiente comando:
```
openstack server add port router puerto_router
```

Le añadimos una IP flotante al router (yo ya tengo una disponible, pero si quisiéramos generar una nueva, lo haríamos con `openstack floating ip create ext-net`):
```
openstack server add floating ip router 172.22.200.191
```

Creamos otro puerto con la dirección 192.168.0.100, que será la IP del cliente conectada a la red interna:
```
openstack port create --network red_interna --fixed-ip ip-address=192.168.0.100 puerto_cliente
```

Generamos un volumen con Debian 11 y 10GB para crear posteriormente el cliente:
```
openstack volume create --image "Debian 11.0 - Bullseye" --size 10 --bootable volumen_cliente
```

Creamos el cliente basado en dicho volumen:
```
openstack server create --flavor vol.mini \                            
--volume volumen_cliente \
--key-name clave_lara \
--port puerto_cliente \
cliente
```

Puesto que las instancias se crean con el grupo de seguridad "default" por defecto, lo quitamos en ambas máquinas:
```
openstack server remove security group router default
openstack server remove security group cliente default
```

Ahora eliminamos la seguridad de los dos puertos conectados a la red interna y del puerto del router conectado a la red externa:
```
openstack port set --disable-port-security puerto_router
openstack port set --disable-port-security puerto_cliente
```

Para deshabilitar la seguridad del puerto conectado a la red externa del router, como no tiene nombre, lo buscamos primero con el siguiente comando:
```
openstack port list --server router
```

Copiamos la ID y ejecutamos el comando anterior identificando el puerto con esta:
```
openstack port set --disable-port-security 3f00269f-391b-4c29-a49f-7820f1a9919f
```

Entramos en el router por SSH para configurar el router-NAT:
```
ssh-keygen -f "/home/lpruna/.ssh/known_hosts" -R "172.22.200.191" 
ssh debian@172.22.200.191
sudo su
echo "1" > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o ens3 -j MASQUERADE
```

Por último, salimos del router, añadimos nuestra clave pública en el agente SSH y volvemos a acceder al router con `ssh -A`.
```
ssh-add ~/.ssh/id_rsa
ssh -A debian@172.22.200.191
```

Después, entramos por SSH normal al cliente y hacemos ping a google.es para probar la conexión a Internet y el funcionamiento del servidor DNS:

<center>
<img src="{static}/images/Openstack/prueba_cliente.png" alt="El cliente accede a Internet" width="750"/>
</center>