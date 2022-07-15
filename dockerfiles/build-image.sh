#!/bin/bash

if [ -z "${1}" ]; then
  echo "Must include directory containing dockerfile"
  exit 1
fi

path=$(echo "$(realpath ${@: -1})")
name=$(echo "${path}" | grep -oe "[^/]*$")
version="$(cat ${path}/version)"
if [ ! -f "${path}/version" ]; then
  version="0.1.0"
fi

echo "docker build -t ${name}:${version} -t ${name}:latest $@"
if ! docker build -t "${name}:${version}" -t "${name}:latest" $@ ; then
  exit 1
fi

if [ -f "${path}/test-image.sh" ]; then
  if ! "${path}/test-image.sh" "${name}-test" "${name}:${version}"; then
    read -p "Image test failed... quit? [Y/n]" quit
    if [ -z "${quit}" ] || [ "${quit}" = "Y" ] || [ "${quit}" = "y" ]; then
      exit 1
    fi
  fi
fi

if [ "${BUILD_IMAGE_PUSH}" = "true" ] || [ "${BUILD_IMAGE_PUSH}" = "True" ] ||
   [ "${BUILD_IMAGE_PUSH}" = "TRUE" ] || [ "${BUILD_IMAGE_PUSH}" = "yes" ] ||
   [ "${BUILD_IMAGE_PUSH}" = "Yes" ] || [ "${BUILD_IMAGE_PUSH}" = "YES" ] ||
   [ "${BUILD_IMAGE_PUSH}" -eq 1 ]; then

  push=y

else
  read -p "Push to remote? [Y/n] " push

fi

if [ -z "${push}" ] || [ "${push}" = "y" ] || [ "${push}" = "Y" ]; then
  if [ -z "${DOCKER_REMOTE_USER}" ]; then
    read -p "Enter remote username (Set ENV var DOCKER_REMOTE_USER to bypass): " user
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
  docker push "${user}/${name}:latest"
fi
