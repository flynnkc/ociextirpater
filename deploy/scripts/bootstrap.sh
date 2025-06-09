
# $TOBEDELETED required to be set
if [ -v TOBEDELETED ]; then echo "#### Extirpate Compartment $TOBEDELETED ####"
else echo "#### ERROR: No compartment set ####" && exit 1
fi

# Variables
EXT_DIR=/usr/local/ociextirpater
VENV=$EXT_DIR/.venv
LOG_DIR=/var/log/ociextirpater

# Oracle Autonomous Linux 9
echo "#### Installing git ####"
sudo yum install -y git

echo "#### Cloning Extirpater Repository ####"
# clone where??
git clone --depth 1 https://github.com/therealcmj/ociextirpater.git $EXT_DIR

# Tested with Python 3.9.21
echo "#### Creating Virtual Environment ####"
python -m venv $VENV
echo "#### Getting Dependencies ####"
$VENV/bin/pip install --upgrade pip
$VENV/bin/pip install -r $EXT_DIR/requirements.txt

echo "#### Making Log Directory ####"
mkdir $LOG_DIR

echo "#### Setting Crontab ####"
echo "0 0 * * * $VENV/bin/python $EXT_DIR/ociextirpate.py -ip -force -c $TOBEDELETED -skip_delete_compartment -log $LOG_DIR/$(date -u +%Y-%m-%d).log" > cron.txt
crontab cron.txt
echo "#### Crontab $(crontab -l) ####"
