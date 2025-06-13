#!/bin/bash

# Variables
EXT_DIR=/usr/local/ociextirpater
VENV=$EXT_DIR/.venv
CURRENT_DT=$(date +%Y-%m-%dT%H:%M:%S)

$VENV/bin/python $EXT_DIR/ociextirpate.py -ip -force -c $1 \
-o compartments -log $2/$CURRENT_DT.log
