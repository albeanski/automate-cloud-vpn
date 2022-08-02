#/bin/sh
key_directory="${PWD}/ssh_keys"

private_key="${key_directory}/ssh_key"
public_key="${private_key}.pub"

if [ ! -d "${key_directory}" ]; then
  echo "'${key_directory}' directory not found..."
  echo "mkdir ${key_directory}"
  mkdir "${key_directory}"
fi

# Generate an ssh keypair with no password and place in files directory
echo "ssh-keygen -f ${private_key} -P \"\" -q"
if ssh-keygen -f "${private_key}" -P "" -q; then
  # Ensure restrictive permissions
  echo "chmod 600 ${public_key}"
  echo "chmod 600 ${private_key}"
  chmod 600 "${public_key}" "${private_key}"
fi
