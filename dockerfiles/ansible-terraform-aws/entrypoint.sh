#!/bin/sh
if [ -f "requirements.yml" ]; then
  echo "Found requirements.yml. Installing..." 2>&1
  ansible-galaxy install -r requirements.yml
fi

if [ -f "pip_requirements.txt" ]; then
  echo "Found pip_requirements.txt. Installing..." 2>&1
  pip3 install -r pip_requirements.txt
fi

if [ "${MANUAL_INSTALL}" = true ]; then
  echo "MANUAL_INSTALL enabled... Skipping startup" 2>&1
else
  echo "Running ansible entrypoint.yml playbook" 2>&1
  ansible-playbook entrypoint.yml
  echo "Running script terraform_build.sh" 2>&1
  ./terraform_build.sh
fi

echo "Creating endless sleep loop to persist container. Press CTRL+C to exit" 2>&1

while :; do
  sleep 300
done
