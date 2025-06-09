
# Variables
# $TOBEDELETED required to be set
if [ -v TOBEDELETED ]; then echo "#### Extirpate Compartment $TOBEDELETED ####"
else echo "#### ERROR: No compartment set ####" && exit 1
fi

VENV=~/ociextirpater/.venv

# Oracle Autonomous Linux 8
echo "#### Installing git ####"
sudo yum install -y git

echo "#### Cloning Extirpater Repository ####"
git clone https://github.com/therealcmj/ociextirpater.git

# Tested with Python 3.9.21
echo "#### Creating Virtual Environment ####"
python -m venv $VENV
echo "#### Getting Dependencies ####"
$VENV/bin/pip install --upgrade pip && $VENV/bin/pip install -r ociextirpater/requirements.txt

echo "#### Setting Crontab ####"
echo "0 0 * * * $VENV/bin/python ociextirpater/ociextirpate.py -ip -force -c $TOBEDELETED" > cron.txt && crontab cron.txt
echo "Crontab $(crontab -l)"
