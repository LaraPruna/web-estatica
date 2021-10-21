#!/usr/bin/env python
# -*- coding: utf-8 -*- #

AUTHOR = 'Lara Pruna'
SITENAME = 'SysRaider'
URL = 'sysraider.larapruna.org'

PATH = 'content'
STATIC_PATHS = ['images', 'extra']

EXTRA_PATH_METADATA = {'extra/favicon.ico': {'path':'favicon.ico'}}

TIMEZONE = 'Europe/Paris'

DEFAULT_LANG = 'es'

THEME = 'theme/pelican-clean-blog'

# Feed generation is usually not desired when developing
FEED_ALL_ATOM = None
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None

# Blogroll
LINKS = (('Pelican', 'https://getpelican.com/'),
         ('Python.org', 'https://www.python.org/'),
         ('Jinja2', 'https://palletsprojects.com/p/jinja/'),)

# Social widget
SOCIAL = (('LinkedIn', 'https://www.linkedin.com/in/lara-pruna-ternero-97887911b/'),
          ('GitHub', 'https://github.com/LaraPruna/'),)

DEFAULT_PAGINATION = 5

# Uncomment following line if you want document-relative URLs when developing
#RELATIVE_URLS = True
