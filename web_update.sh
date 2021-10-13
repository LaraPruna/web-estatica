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

#Se generará la carpeta de salida en otro repositorio:
pelican -o ../salida-web-estatica

#Se suben los cambios en la carpeta de salida a su repositorio:
git add .
git commit -m "Sitio web actualizado"
git push

#Automáticamente, Netlify actualizará el sitio web.
