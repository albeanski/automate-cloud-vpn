#!/bin/sh
if [ -f "/project/requirements.yml" ]; then
  ansible-galaxy install -r requirements.yml
fi

if [ -f "/project/pip_requirements.txt" ]; then
  pip3 install -r /project/pip_requirements.txt
fi

echo "Creating endless sleep loop to persist container. Press CTRL+C to exit" 2>&1

while :; do
  sleep 300
done
