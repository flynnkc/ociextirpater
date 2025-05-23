#!/bin/bash

# Variables
# $TOBEDELETED required to be set
if [ -v TOBEDELETED ]; then echo "Compartment $TOBEDELETED"; else echo "No compartment set" && exit 1; fi
VENV=~/ociextirpater/.venv

# Oracle Autonomous Linux 9
sudo yum install -y git
git clone https://github.com/therealcmj/ociextirpater.git

# Tested with Python 3.9.21
python -m venv $VENV
$VENV/bin/pip install --upgrade pip && $VENV/bin/pip install -r ociextirpater/requirements.txt

echo "0 0 * * * $VENV/bin/python ociextirpater/ociextirpate.py -ip -force -c $TOBEDELETED" > cron.txt && crontab cron.txt
echo "Crontab $(crontab -l)"
