#!/bin/bash

name="${1}-test"
image="${1}:${2}"

echo "Creating container '${name}' to test image '${image}'..."

docker run --rm -itd --name "${name}" "${image}" >/dev/null

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

echo "Testing complete. Removing container '${name}'"
docker rm -f "${name}" >/dev/null

if [ "${fail}" -ne 0 ]; then
  exit 1
fi

exit 0
