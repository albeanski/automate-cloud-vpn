#!/bin/bash
if [ ! -f "/.dockerenv" ] &&  [ "${NO_CONTAINER_LOCK}" != true ]; then
  # Do a check to make sure this is being run inside a docker container. The image should have included a CONTAINER_LOCK env var
  echo "Syncing runtime directory not allowed outside of container. Set NO_CONTAINER_LOCK=true to bypass." 2>&1
  exit 1
fi

cp -v -R /project/* /runtime/

cd /project
ansible-playbook entrypoint.yml
