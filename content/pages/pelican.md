Title: Pelican
Date: 2021-10-06 14:28
Slug: pelican
Authors: Lara Pruna

# ¿Te interesa crear tu propia web estática con Pelican en Debian?

Aquí aprenderás a hacerlo sin problemas. Como sabrás, Pelican es un generador de páginas estáticas basado en Python, y es bastante fácil de usar. Sigue con atención los siguientes pasos:

## Primeros pasos en Pelican

Instala el paquete con pip, y opcionalmente, con markdown. Si no tienes pip, puedes instalarlo como cualquier paquete de Debian:
<pre><code class="shell">
apt install python3-pip
pip install "pelican[markdown]"
</code></pre>

Genera tu sitio web:
<pre><code class="shell">
pelican-quickstart
</code></pre>

El programa te preguntará el nombre de tu nueva web, en qué directorio quieres guardarlo, nombre completo del creador, si quieres activar la paginación, etc.

<img src="{static}/images/yes.png" alt="Conseguido" width="100" align="middle"/>
Ya tienes lo básico.

Ahora puedes probar a escribir un artículo. Tan solo tienes que crear un fichero en markdown o en el lenguaje que hayas elegido y guardarlo en el directorio "content". Veamos un ejemplo:
<pre><code class="markdown">
Title: Mi primer artículo
Date: 2021-10-05 9:10
Category: Review
lang: es

Hola, esto es una prueba.
</code></pre>

Después, ejecuta el siguiente comando para guardar los cambios que hayas hecho en la carpeta:
<pre><code class="shell">
pelican content
</code></pre>

Es posible que, al generar el sitio web, no se haya creado automáticamente el directorio "images" dentro de la carpeta "content". En ese caso, al ejecutar el comando anterior saltará una alerta de tipo "Warning". Para solucionarlo, simplemente tendríamos que crear la carpeta a mano. Ya solo nos quedaría desplegar la previsualización en el navegador. Para ello, introducimos el comando:
<pre><code class="shell"> 
pelican --listen
</code></pre>

El programa nos devolverá una dirección http (http://localhost:8000). Copiamos dicha dirección en el navegador y ¡voila!

<img src="{static}/images/primer_articulo.png" alt="Mi primer articulo" width="700" align="middle"/>

