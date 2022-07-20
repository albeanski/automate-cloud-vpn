#!/bin/bash

name="${1}"
image="${2}"

echo "Creating container '${name}' to test image '${image}'..."
echo "docker run -itd --name \"${name}\" \"${image}\""
if ! docker run -itd --name "${name}" "${image}"; then
  echo "Something went wrong... printing logs"
  docker logs "${name}"
  docker rm -f "${name}" >/dev/null
  exit 1
fi

fail=0
echo -n "ansible... "
if docker exec -it "${name}" ansible --version >/dev/null; then
  echo "PASS"
else
  echo "FAIL"
  fail=1
fi

echo -n "terraform... "
if docker exec -it "${name}" terraform --version >/dev/null; then
  echo "PASS"
else
  echo "FAIL"
  fail=1
fi

echo -n "aws-cli... "
if docker exec -it "${name}" aws --version >/dev/null; then
  echo "PASS"
else
  echo "FAIL"
  fail=1
fi

echo -n "wireguard... "
if docker exec -it "${name}" wg --version >/dev/null; then
  echo "PASS"
else
  echo "FAIL"
  fail=1
fi

echo "Testing complete. Removing container '${name}'"
docker rm -f "${name}" >/dev/null

if [ "${fail}" -ne 0 ]; then
  exit 1
fi

exit 0
