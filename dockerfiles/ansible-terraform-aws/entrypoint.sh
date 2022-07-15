#!/bin/sh
if [ -f "requirements.yml" ]; then
  echo "Found requirements.yml. Installing..." 2>&1
  ansible-galaxy install -r requirements.yml
fi

if [ -f "pip-requirements.txt" ]; then
  echo "Found pip-requirements.txt. Installing..." 2>&1
  pip3 install -r pip-requirements.txt
fi

echo "Running ansible entrypoint.yml playbook" 2>&1
ansible-playbook entrypoint.yml

if [ "${MANUAL_INSTALL}" = true ]; then
  echo "MANUAL_INSTALL enabled... Skipping run.sh" 2>&1
else
  echo "Running script run.sh" 2>&1
  ./run.sh
fi

echo "Creating endless sleep loop to persist container. Press CTRL+C to exit" 2>&1

while :; do
  sleep 300
done
