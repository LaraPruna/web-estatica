Title: Pull Request en Github
Date: 2021-09-24 16:45
Category: Implantación de Aplicaciones Web
lang: es
tags: GitHub
modified: 2021-11-01 20:01
Header_Cover: images/covers/PullRequest.jpg
summary: Vamos a aprender a hacer un Pull Request al repositorio de otro perfil de GitHub.

El **Pull Request** es una petición que se hace al propietario de un repositorio para realizar un cambio en el mismo. Si el propietario está de acuerdo, aceptará el cambio y actualizará el repositorio con la nueva versión.

<img src="{static}/images/high_five.png" alt="Choca esos cinco" width="150"/> En otras palabras, se trata de una colaboración.

## Enviar el Pull Request

### Antes de hacer el cambio

Estos son los pasos que tenemos que seguir antes de realizar el Pull Request:

Primero, creamos una rama (*fork*) pulsando en ese mismo botón en el repositorio.

<img src="{static}/images/github/fork.png" alt="Botón fork" width="1000"/>

Clonamos el repositorio (con ssh, para que nos pida la clave en lugar de la contraseña del usuario):
```
git clone git@github.com:LaraPruna/web-estatica-pelican.git
```

Creamos una rama nueva:
```
git checkout -b pr_lpt
```

<img src="{static}/images/yes.png" alt="Hora de juguetear" width="150"/> Ya podemos cambiar lo que queramos.

<br>

### Después de hacer el cambio

Añadimos los cambios a la rama y los confirmamos:
```
git add .
git commit -m "He añadido un nuevo fichero" 
```

Identificamos el nombre del repositorio remoto con el siguiente comando. En mi caso, es "origin".
```
git remote
```

Enviamos los cambios con `git push`, el repositorio remoto y el nombre de nuestra rama:
```
git push origin pr_lpt
```

Por último, creamos el Pull Request pulsando el botón que nos aparecerá en el repositorio:

<img src="{static}/images/github/pull_request.png" alt="Botón fork" width="250"/>

Para sincronizar nuestra rama con el repositorio remoto, revisamos en qué rama estamos. La rama en la que nos encontramos se mostrará en verde.
```
git branch
```

Si no nos encontramos en nuestra rama principal (main o master), cambiamos a esta:
```
git checkout main
```

Añadimos el repositorio original como un repositorio upstream, si no lo tenemos ya:
```
git remote add upstream https://github.com/josedom24/prueba-pr-asir.git
```

Buscamos los cambios del repositorio original:
```
git fetch upstream
```

Fusionamos nuestra rama principal con el repositorio original:
```
git merge upstream/main
```

Mandamos los cambios a GitHub:
```
git push origin main
```

Y ya solo nos quedaría esperar que el propietario del repositorio...

<img src="{static}/images/espia.png" alt="Observando a distancia" width="150"/> ...nos acepte el cambio.

## Recibir el Pull Request

Cuando recibamos un Pull Request, nos aparecerá la propuesta en la pestaña "commit" de nuestro repositorio.

<img src="{static}/images/llamada.png" alt="Llamando a Dani" width="150"/> Me he servido de la ayuda de mi compi Daniel para hacer la prueba.

Aquí os muestro el resultado de su Pull Request:

<img src="{static}/images/github/PR_Daniel.png" alt="Pull Request de Daniel" width="1000"/>

Después, aceptamos el cambio...

<img src="{static}/images/maldad.png" alt="WAAJAJAJAJA" width="200"/> ... o lo rechazamos.

Así queda el sitio web después de aceptar el Pull Request y actualizar el repositorio.

<img src="{static}/images/github/web_actualizada.png" alt="Web actualizada con un nuevo artículo" width="1000"/>
