#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

container_path="/wireguard/client"
path="/etc/wireguard"

usage() {
 echo "usage: ./fetch_wireguard_files.sh [OPTIONS] [CONTAINER NAME]

CONTAINER_NAME          Specify container name instead of searching in docker-compose.yml
                        Useful if the parser doesnt find the correct container name.

OPTIONS
-------
-p LOCAL_DESTINATION_PATH     Local destination path to copy files to (/etc/wireguard)
-r USER@HOST:REMOTE_PATH      Use rsync to copy files to remote host
                              (ie: john@192.168.0.101:~/ or ron@host.mydomain.com:/tmp)
"
}

exit_usage() {
  usage
  exit 1
}

# $1 container name
# $2 container path
# $3 local path
fetch_local() {
  echo "docker exec ${1} cat ${2}/privatekey | sudo tee ${3}/privatekey"
  docker exec ${1} cat ${2}/privatekey | sudo tee "${3}/privatekey" > /dev/null

  echo "docker exec ${1} cat ${2}/publickey | sudo tee ${3}/publickey"
  docker exec ${1} cat ${2}/publickey | sudo tee "${3}/publickey" > /dev/null

  echo "docker exec ${1} cat ${2}/wg0.conf | sudo tee ${3}/wg0.conf"
  docker exec ${1} cat ${2}/wg0.conf | sudo tee "${3}/wg0.conf" > /dev/null
}

# $1 container name
# $2 container path
# $3 user@host:dest_path
fetch_remote() {
  timestamp=$(date +%N)
  tmp_path="/tmp/wg_fetch_${timestamp}"
  mkdir "${tmp_path}"
  echo "docker exec ${1} cat ${2}/privatekey | sudo tee ${tmp_path}/privatekey"
  docker exec ${1} cat ${2}/privatekey | sudo tee "${tmp_path}/privatekey" > /dev/null

  echo "docker exec ${1} cat ${2}/publickey | sudo tee ${tmp_path}/publickey"
  docker exec ${1} cat ${2}/publickey | sudo tee "${tmp_path}/publickey" > /dev/null

  echo "docker exec ${1} cat ${2}/wg0.conf | sudo tee ${tmp_path}/wg0.conf"
  docker exec ${1} cat ${2}/wg0.conf | sudo tee "${tmp_path}/wg0.conf" > /dev/null

  echo "rsync -v ${tmp_path}/privatekey ${tmp_path}/publickey ${tmp_path}/wg0.conf ${3}"
  rsync -v "${tmp_path}/privatekey" "${tmp_path}/publickey" "${tmp_path}/wg0.conf" "${3}"

  echo "rm -rf ${tmp_path}"
  rm -rf "${tmp_path}"
}

while getopts "p:r::" options; do
case "${options}" in
  p)
    path_arg="${OPTARG}"
    path="${path_arg}"
    ;;

  r)
    remote="${OPTARG}"
    ;;

  :)
    echo "Error: -${OPTARG} requires an argument."
    exit_usage
    ;;

  *)
    exit_usage

esac
done

# Remove any trailing slashes
path="${path%"${path##*[!/]}"}"

# Ensure only one non-opt argument at the end
shift $((OPTIND-1))
if [ "$#" -gt 1 ]; then
  exit_usage
fi

# Get container name from docker-compose.yml if it wasn't provided
if [ -z "${1}" ]; then
  container_name=$(cat ./docker-compose.yml | grep -oP -e "(?<=container_name:).*$" )
else
  container_name="${1}"
fi

if [ ! -z "${remote}" ]; then
  if [ ! -z "${path_arg}" ]; then
    echo "-r and -p cannot be set at the same time. Choose either -r (remote) or -p (local) only."
    exit 1
  fi

  # remote dest was specified
  if ! which rsync; then
    # Ensure rsync is installed if using -r
    echo "Using -r option requires rsync fo be installed on this machine."
    exit 1
  fi

  fetch_remote "${container_name}" "${container_path}" "${remote}"

else
  # Ensure path exists
  if [ ! -z "${path}" ] && [ ! -d "${path}" ]; then
    echo "Directory doesnt exist: ${path}"
    exit 1
  fi

  fetch_local "${container_name}" "${container_path}" "${path}"

fi

