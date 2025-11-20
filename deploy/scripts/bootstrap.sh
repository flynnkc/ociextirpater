
# Variables
EXT_DIR=/usr/local/ociextirpater
VENV=$EXT_DIR/.venv
LOG_DIR=/var/log/ociextirpater
MAX_ATTEMPTS=5

# Function to attempt a command with retries
attempt_with_retry() {
  local attempt=0
  local command="$1"
  while [ $attempt -lt $MAX_ATTEMPTS ]; do
    if $command; then
      return 0
    else
      echo "Failed. Retrying in 5 seconds..."
      sleep 5
      attempt=$((attempt + 1))
    fi
  done
  echo "Failed after $MAX_ATTEMPTS attempts."
  return 1
}

# Oracle Autonomous Linux 9
echo "#### Installing git ####"
attempt_with_retry "sudo yum install -y git"
if [ $? -eq 1 ]; then
  exit 1
fi

echo "#### Cloning Extirpater Repository ####"
#attempt_with_retry "git clone --depth 1 https://github.com/therealcmj/ociextirpater.git $EXT_DIR"
attempt_with_retry "git clone -b terraform --depth 1 https://github.com/flynnkc/ociextirpater.git $EXT_DIR"
if [ $? -eq 1 ]; then
  exit 1
fi

echo "#### Setting Executables ####"
chmod 550 $EXT_DIR/deploy/scripts/daily.sh

# Tested with Python 3.9.21
echo "#### Creating Virtual Environment ####"
attempt_with_retry "python -m venv $VENV"
if [ $? -eq 1 ]; then
  exit 1
fi

echo "#### Getting Dependencies ####"
# Upgrading pip is not a hard requirement but a nice to have
attempt_with_retry "$VENV/bin/pip install --upgrade pip"
attempt_with_retry "$VENV/bin/pip install -r $EXT_DIR/requirements.txt"
if [ $? -eq 1 ]; then
  exit 1
fi

echo "#### Making Log Directory ####"
mkdir $LOG_DIR

echo "#### Setting Crontab ####"
echo "0 0 * * * $EXT_DIR/deploy/scripts/daily.sh $TOBEDELETED $LOG_DIR $EXT_TAG" > cron.txt
crontab cron.txt
echo "#### Crontab $(crontab -l) ####"
