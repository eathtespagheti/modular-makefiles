EXTRA-SERVICES ::= db

include .makefiles/django.mk

SECRETS_FOLDER ::= secrets
SECRETS_LIST ::= db-password django-secret-key
