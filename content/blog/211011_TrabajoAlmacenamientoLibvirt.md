Title: Práctica de almacenamiento en libvirt
Date: 2021-10-11 18:47
Category: KVM/QEMU
lang: es
tags: Almacenamiento,KVM,QEMU,libvirt,LVM
summary: Vamos a aprender a gestionar el almacenamiento en libvirt. Para ello, crearemos un pool de almacenamiento de tipo LVM y otro de tipo directorio. En cada uno de estos grupos, generaremos nuevos volúmenes y, con ellos, máquinas virtuales. Además, emplearemos imágenes con formato raw y qcow2.

Vamos a aprender a gestionar el almacenamiento en libvirt. Para ello, crearemos un pool de almacenamiento de tipo LVM y otro de tipo directorio. En cada uno de estos grupos, generaremos nuevos volúmenes y, con ellos, máquinas virtuales. Además, emplearemos imágenes con formato raw y qcow2.

<img src="{static}/images/programando.png" alt="Hora de jugar" width="150"/> Vamos a jugar un poco con el almacenamiento en libvirt.


## Pool de almacenamiento de tipo LVM

Empecemos por **pool de almacenamiento de tipo LVM** con "pool-define-as". Después de definirlo, lo iniciaremos con "pool-start":
<pre><code class="shell">
sudo virsh -c qemu:///system pool-define-as vg01 --type logical
sudo virsh -c qemu:///system pool-start vg01
</code></pre>

Dentro de este pool, creamos un **volumen lógico** de 3GiB:
<pre><code class="shell">
sudo virsh -c qemu:///system vol-create-as pool01 original_lara --capacity 3GiB
</code></pre>

Con el volumen que hemos creado, he instalado una máquina llamada "original_lara", con 1GiB de memoria y la última imagen de Debian 11 para la arquitectura amd64:
<pre><code class="shell">
sudo virt-install --name original_lara --disk /dev/pool01/vol01 --memory 1024 --cdrom ~/Descargas/debian-11.0.0-amd64-netinst.iso
</code></pre>

Podemos comprobar que la máquina se ha creado con el volumen vol01 ejecutando el siguiente comando:
<pre><code class="shell">
sudo virsh -c qemu:///system domblklist original_lara
</code></pre>


## Conversión del formato de imagen

Como a la hora de crear el volumen lógico no hemos especificado ningún formato, el que tendrá por defecto es **raw**. Vamos a *convertir* el volumen a formato qcow2 (aunque, más que convertir, lo que haremos es crear una copia en un formato distinto), y se guardará en el pool default:
<pre><code class="shell">
sudo qemu-img convert /dev/pool01/vol01 /var/lib/libvirt/images/original_lara.qcow2
</code></pre>

A partir de la imagen base en formato qcow2, podemos crear máquinas virtuales con **aprovisionamiento ligero**. Yo he creado dos nodos:
<pre><code class="shell">
sudo qemu-img create -b /var/lib/libvirt/images/original_lara.qcow2 -f qcow2 /var/lib/libvirt/images/nodo1_lara.qcow2
sudo qemu-img create -b /var/lib/libvirt/images/original_lara.qcow2 -f qcow2 /var/lib/libvirt/images/nodo2_lara.qcow2
sudo virt-install --name nodo1-lara --disk /var/lib/libvirt/images/nodo1_lara.qcow2 --import --memory 1024
sudo virt-install --name nodo2-lara --disk /var/lib/libvirt/images/nodo2_lara.qcow2 --import --memory 1024
</code></pre>

Antes hemos convertido la imagen qcow2 a raw, pero también podemos hacerlo **a la inversa** (asegurémonos antes de que la máquina está apagada):
<pre><code class="shell">
sudo qemu-img convert /var/lib/libvirt/images/nodo1_lara.qcow2 /var/lib/libvirt/images/nodo1_lara.raw
</code></pre>

Una vez hayamos generado la copia de la imagen en formato raw, entramos en el fichero xml de la máquina y cambiamos la imagen qcow2 por la raw:
<pre><code class="shell">
sudo virsh edit --domain nodo1-lara
</code></pre>

<pre><code class="xml">
<driver name='qemu' type='raw'/>
      <source file='/var/lib/libvirt/images/nodo1_lara.raw'/>
</code></pre>


## Redimensionamiento de las imágenes

Imaginemos que tenemos que añadirle más tamaño a la imagen del nodo 2, por ejemplo, 1GiB más. Primero, redimensionamos la imagen en sí con el siguiente
comando:
<pre><code class="shell">
sudo qemu-img resize /var/lib/libvirt/images/nodo2_lara.qcow2 +1G
</code></pre>

Para aumentar también el **sistema de ficheros**, crearemos una imagen idéntica a la del nodo2, solo que con un gigabyte más. Después, la sustituiremos por la original:
<pre><code class="shell">
sudo qemu-img create -f qcow2 -o preallocation=metadata -a /var/lib/libvirt/images/nodo2_lara_copia.qcow2 4G
sudo virt-resize --expand /dev/sda1 /var/lib/libvirt/images/nodo2_lara.qcow2 /var/lib/libvirt/images/nodo2_lara_copia.qcow2
sudo rm /var/lib/libvirt/images/nodo2_lara.qcow2 .
sudo mv /var/lib/libvirt/images/nodo2_lara_copia.qcow2 /var/lib/libvirt/images/nodo2_lara.qcow2
</code></pre>


## Creación de instantáneas (snapshots)

Antes de generar la instantánea, tenemos que tener en cuenta que el comando que vamos a usar es alérgico al formato raw. Por lo tanto, será mejor que lo *convirtamos* antes a qcow2 (guiño, guiño), y luego aplicamos el comando:
<pre><code class="shell">
sudo virsh snapshot-create-as --domain nodo1-lara --name nodo1_snap
</code></pre>

<img src="{static}/images/demonio.png" alt="Maldad" width="150"/>
Ahora sería un buen momento para maltratar un poco al nodo.

Estas son algunas ideas: comenta líneas del fichero /etc/fstab, cámbiale la cantidad de memoria en el fichero xml, crea o elimina diferentes ficheros... Cuando hayamos acabado de hacer diabluras, restauraremos la máquina con la instantánea:
<pre><code class="shell">
sudo virsh snapshot-revert nodo1-lara nodo1_snap
</code></pre>


## Pool de almacenamiento de tipo directorio

Vamos a definir e iniciar un pool de tipo directorio llamado "discos_externos", al igual que hicimos con el de tipo LVM:
<pre><code class="shell">
sudo virsh -c qemu:///system pool-define-as pool_dir --type dir --target ./pool_dir
sudo virsh -c qemu:///system pool-start pool_dir
</code></pre>

Y dentro, crearemos un volumen de 1GiB:
<pre><code class="shell">
sudo virsh -c qemu:///system vol-create-as pool_dir vol_dir --capacity 1GiB
</code></pre>

Podemos añadir este volumen en caliente a cualquiera de las máquinas, por ejemplo, al nodo2:
<pre><code class="shell">
sudo virsh -c qemu:///system attach-disk nodo2-lara ./pool_dir/vol_dir vdb
</code></pre>

Al acceder al nodo2, crearemos una nueva partición con el comando "fdisk /dev/vda", le daremos un sistema de ficheros con "mkfs" (para dejarlo como ext4, el comando sería "mkfs.ext4" seguido de la partición) y, por último, lo montamos con "mount". Recuerda, todos estos comandos han de ejecutarse como root.
