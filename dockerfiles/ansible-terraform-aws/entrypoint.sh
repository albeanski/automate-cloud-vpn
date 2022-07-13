#!/bin/sh
echo "Running ansible entrypoint.yml playbook" 2>&1
ansible-playbook entrypoint.yml

if [ -f "/runtime/requirements.yml" ]; then
  ansible-galaxy install -r requirements.yml
fi

if [ -f "/runtime/pip-requirements.txt" ]; then
  pip3 install -r /project/pip-requirements.txt
fi

echo "Creating endless sleep loop to persist container. Press CTRL+C to exit" 2>&1

while :; do
  sleep 300
done
