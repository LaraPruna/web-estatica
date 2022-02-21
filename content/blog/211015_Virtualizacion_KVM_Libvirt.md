Title: Uso básico de virsh
Date: 2021-09-30 18:55
Category: Cloud Computing
lang: es
tags: Virtualización,KVM,QEMU,libvirt
Header_Cover: images/covers/qemu.jpg
summary: Crearemos una red interna, generaremos un volumen en el pool por defecto con una imagen qcow2 y montaremos la imagen con qemu-nbd.

# Uso básico de virsh

¿Abierto a nuevas experiencias?¿Virtualbox se te ha quedado pequeño?¿Te han obligado a pasarte a KVM y no sabes cómo?

<img src="{static}/images/rock.png" alt="Hora de Rock & Roll" width="150"/>
¡Entonces este es tu sitio!

En un momento vamos a aprender cómo crear una red interna en KVM/QEMU con virsh, generaremos un volumen en el pool por defecto con una imagen qcow2 y montaremos dicha imagen con qemu-nbd.

<br>

## Crear una red interna

Primero, para crear una red con virsh, es necesario generar un fichero XML con una determinada configuración.
```
nano red_interna.xml
```

Para que la red sea interna de tipo NAT, debería tener un aspecto similar a este:
```
 <network>
    <name>red_interna</name>
    <bridge name="virbr2"/>
    <forward mode="nat"/> 
    <model type="virtio"/>
    <ip address="10.0.1.1" netmask="255.255.255.0">
      <dhcp>
        <range start="10.0.1.2" end="10.0.1.254"/>
      </dhcp>
    </ip>
  </network>
```

Guardamos el fichero y lo añadimos la lista de redes virtuales de QEMU:
```
virsh -c qemu:///system net-create --file red_interna.xml
```
<img src="{static}/images/ojo.png" alt="Ojo cuidao" width="150"/>
**OJO CUIDAO**

El comando net-create no crea las redes de manera **persistente**, es decir, que se irán a tomar viento fresco en cuanto apaguemos o reiniciemos el host. Para mantener las redes de forma indefinida, en su lugar emplearemos el comando net-define.

Estas son otras acciones que puedes hacer con las redes:

* Eliminar la red: net-destroy
* Iniciar la red: net-start
* Configurar la red para que se inicie automáticamente al iniciar el host: net-autostart
* Ver la configuración XML de la red: net-dumpxml
* Editar el fichero XML de la red: net-edit
* Ver la lista de redes registradas en el sistema: net-list
* Ver información sobre la red: net-info
* Hacer que la red deje de ser persistente: net-undefine

Ahora que tenemos creada nuestra red interna de tipo NAT, podemos iniciarla si no lo está aún:
```
virsh -c qemu:///system net-start red_interna
```
<br>

## Montar una imagen qcow2 con qemu-nbd

Vamos a cargar el módulo nbd en memoria para habilitarlo, asegurándonos de que pueda soportar un número alto de particiones (por ejemplo, 8):
```
sudo modprobe nbd max_part=8
```

Conectamos nuestro fichero qcow2 como un dispositivo de bloque (/dev/nbd0):
```
sudo qemu-nbd --connect=/dev/nbd0 ~/debiantest.qcow2
```

Con fdisk, podemos ver las particiones del dispositivo de bloque:
```
sudo fdisk /dev/nbd0 -l
```

Creamos un directorio en /mnt y montamos la primera partición de la máquina virtual en esa carpeta:
```
sudo mkdir /mnt/nbd
sudo mount /dev/nbd0p1 /mnt/nbd/
```

<img src="{static}/images/alivio.png" alt="Hecho" width="150"/>
¡Aparcao!

Ahora podremos ver el contenido de la imagen qcow2 y hacer los cambios oportunos, como definir una nueva contraseña para el usuario:
```
sudo chroot /mnt/nbd
passwd usuario
```

O copiar nuestra clave pública en la máquina virtual para poder entrar después por SSH. Para ello, nos conectados como root, creamos el directorio .ssh en la máquina virtual y redirigimos nuestra clave pública al fichero authorized_keys dentro de esa carpeta:
```
sudo cat ~/.ssh/id_rsa.pub > /mnt/nbd/.ssh/authorized_keys
```

También podemos aprovechar para cambiar el nombre de la máquina, editando los ficheros /etc/hostname y /etc/hosts
```
echo maquina_lara > /mnt/nbd/etc/hostname
sed -i 's/debiantest/maquina_lara/g' "/mnt/nbd/etc/hosts"
```

Cuando terminemos de hacer los cambios, desmontamos la máquina virtual:
```
umount /mnt/nbd/
```
<br>

## Crear un volumen en el pool por defecto con la imagen

En el volumen que vamos a crear, al que llamaremos "voltest", subiremos la imagen qcow2 de la sección anterior, por lo que tendremos que darle también un formato qcow2 y 10GB de capacidad. Recuerda que "create" significa en virsh "crear temporalmente". Si quisiéramos generar un volumen para tenerlo de manera indefinida, usaríamos "vol-define-as":
```
virsh -c qemu:///system vol-create-as --format qcow2 --name voltest --capacity 10GiB --pool default
```

Ahora que ya tenemos el contenedor preparado, vamos a introducir el contenido:
```
virsh -c qemu:///system vol-upload voltest debiantest.qcow2 --pool default
```
<br>

## Definir el dominio con un fichero XML y conectado a la red creada

Dejadme aclarar antes para los novicios el término "dominio". No debemos confundirlo con el dominio de un sitio web; en virsh, se le llama así a las máquinas virtuales. Quizá no sea el mejor término para referirse a ellas...

<img src="{static}/images/enfin.png" alt="Qué se le va a hacer" width="150"/>
Pero en fin...

Antes de definir un dominio, necesitamos un fichero XML donde alojar su configuración, que incluirá la red que hemos creado en la primera sección:
```
nano dominio1.xml
```
```
<domain type="kvm">
  <name>maquina_lara</name>
  <memory unit="G">1</memory>
  <vcpu>1</vcpu>
  <os>   
    <type arch="x86_64">hvm</type>
  </os>  
  <devices>
    <emulator>/usr/bin/kvm</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/var/lib/libvirt/images/maquina_lara'/>
      <target dev="vda" bus="virtio"/>
    </disk>
    <interface type="network">
      <source network="red_interna"/>
      <mac address="52:54:00:86:c6:a9"/>
      <model type="virtio"/>
    </interface>
    <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0' />
  </devices>
</domain>
```

Ya podemos definir el dominio:
```
virsh -c qemu:///system define dominio1.xml
```
<br>

## Arrancar el dominio y acceder a la máquina por ssh:

Primero, iniciamos la red interna que hemos creado:
```
virsh -c qemu:///system net-start red_interna
```

Después, arrancamos el dominio:
```
virsh -c qemu:///system start maquina_lara
```

Vamos a entrar un momentito con el visor remoto ("virt-viewer"), nos conectamos como root para levantar la interfaz, que estará caída, y le pedimos una IP al servidor DHCP:
```
virt-viewer maquina_lara
sudo su
ip l set enp0s3 up
dhclient
```

Y finalmente nos salimos del visor para entrar por SSH:
```
ssh usuario@10.0.1.226
```

<img src="{static}/images/fiesta.png" alt="¡Olé!" width="150"/>
¡Ya tenemos listo nuestro dominio!

En resumen, hemos creado una red interna y un volumen a partir de una imagen qcow2 (que hemos acondicionado previamente), y con esos dos elementos hemos generado una máquina virtual con una red NAT a la que podemos acceder por SSH.
