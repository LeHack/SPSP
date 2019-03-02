import os

from setuptools import setup

here = os.path.abspath(os.path.dirname(__file__))

with open(os.path.join(here, 'requirements.txt')) as f:
    requires = f.read()

setup(
    version='devel',
    name='spsp-ui',
    description='UI Systemu Pomiaru Stężenia Pyłu w powietrzu',
    install_requires=requires,
)
