#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
from setuptools import setup

VERSION = '1.9.8'

setup(
    name='grabserial',
    version=VERSION,
    scripts=['grabserial',],
    #packages=['grabserial',],
    author='Tim Bird',
    author_email='tbird20d@yahoo.com',

    maintainer='Tim Bird',
    maintainer_email='tbird20d@yahoo.com',

    description='Serial dump and timing program',
    long_description='''
grabserial is a small program which reads a serial port and writes the data
to standard output. The main purpose of this tool is to collect messages
written to the serial console from a target board running Linux, and save
the messages on a host machine.
''',
    url='http://github.com/tbird20d/grabserial',
    license='GPL v2',
    keywords='grabserial serial boot time optimization tool',
    classifiers=[
        "Topic :: Utilities",
        "Environment :: Console",
        "Intended Audience :: Developers",
        "Natural Language :: English",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 2.7",
        "Topic :: Software Development :: Embedded Systems",
    ],

    install_requires=[
        "pyserial>=2.6"
    ],
)
