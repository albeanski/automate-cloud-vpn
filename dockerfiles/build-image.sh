#!/bin/sh
name=$(echo "${PWD}" | grep -oe "[^/]*$")
version="$(cat ${PWD}/version)"
if [ ! -f "${PWD}/version" ]; then
  version="0.1.0"
fi

echo "docker build -t ${name}:${version} -t ${name}:latest ."
docker build -t "${name}:${version}" -t "${name}:latest" "$@" .

read -p "Push to remote? [Y/n] " push

if [ -z "${push}" ] || [ "${push}" = "y" ] || [ "${push}" = "Y" ]; then
  if [ -z "${DOCKER_REMOTE_USER}" ]; then
    read -p "Enter remote username: " user
    if [ -z "${user}" ]; then
      echo "User cancelled..."
      exit 1
    fi

  else
    user="${DOCKER_REMOTE_USER}"

  fi

  docker login

  docker tag "${name}:${version}" "${user}/${name}:${version}"
  docker tag "${name}:${version}" "${user}/${name}:latest"

  docker push "${user}/${name}:${version}"

fi
