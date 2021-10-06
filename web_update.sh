#!/bin/bash

#Este script se encarga de actualizar el sitio web generado con Pelican y alojado
#en Netlify, aunque también podría funcionar con Render. El script estará guardado
#en el mismo directorio que Pelican.

#Primero se sube los cambios al repositorio de Pelican en GitHub:
echo "Introduce la contraseña de tu clave ssh:"
git add .
git commit -m "Nuevos cambios en el repositorio"
git push

#Después se exporta el contenido html del sitio web a un directorio determinado.
#Yo he decidido guardarlo en mi repositorio conectado con Netlify, seleccionando
#el tema:
pelican -o ../web-estatica-netlify -t pelican-clean-blog

#Por último, actualizo el repositorio de GitHub conectado con Netlify:
cd ../web-estatica-netlify
git add .
git commit -m "Sitio web actualizado"
git push
