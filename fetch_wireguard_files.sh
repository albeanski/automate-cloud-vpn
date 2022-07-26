#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

usage() {
 echo "usage: ./fetch_wireguard_files.sh [OPTIONS] [CONTAINER NAME]

CONTAINER_NAME          Specify container name instead of searching in docker-compose.yml
                        Useful if the parser doesnt find the correct container name.

OPTIONS
-------
-p DESTINATION_PATH     Destination path to copy files to"

}

exit_usage() {
  usage
  exit 1
}

path="/etc/wireguard"
while getopts "p::" options; do
case "${options}" in
  p)
    path="${OPTARG}"
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
else  container_name="${1}"
fi

# Ensure path exists
if [ ! -z "${path}" ] && [ ! -d "${path}" ]; then
  echo "Directory doesnt exist: ${path}"
  exit 1
fi

echo "docker exec ${container_name} cat /wireguard/client_privatekey | sudo tee ${path}/privatekey"
docker exec ${container_name} cat /wireguard/client_privatekey | sudo tee "${path}/privatekey" > /dev/null

echo "docker exec ${container_name} cat /wireguard/client_publickey | sudo tee ${path}/publickey"
docker exec ${container_name} cat /wireguard/client_publickey | sudo tee "${path}/publickey" > /dev/null

echo "docker exec ${container_name} cat /wireguard/client_wg0.conf | sudo tee ${path}/wg0.conf"
docker exec ${container_name} cat /wireguard/client_wg0.conf | sudo tee "${path}/wg0.conf" > /dev/null
