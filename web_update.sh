#!/bin/bash

#Este script se encarga de actualizar el sitio web generado con Pelican y alojado
#en Netlify, aunque también podría funcionar con Render. El script estará guardado
#en el mismo directorio que Pelican.

#Primero se actualiza el contenido del sitio web:
pelican content -s pelicanconf.py

#Luego se suben los cambios al repositorio de Pelican en GitHub:
git add .
git commit -m "Sitio web actualizado"
git push
