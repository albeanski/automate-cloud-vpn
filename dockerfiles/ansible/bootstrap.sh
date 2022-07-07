#!/bin/sh
if [ -f "/project/requirements.yml" ]; then
  ansible-galaxy install -r requirements.yml
fi

if [ -f "/project/pip-requirements.txt" ]; then
  pip3 install -r /project/pip-requirements.txt
fi

tail -f /dev/null
