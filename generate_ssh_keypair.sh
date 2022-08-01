#/bin/sh
if [ -d "./project" ]; then
  key_directory="${PWD}/project/files"
else
  key_directory="${PWD}/files"
fi

private_key="${key_directory}/ssh_key"
public_key="${private_key}.pub"

if [ ! -d "${key_directory}" ]; then
  "Creating '${key_directory}' directory..."
  mkdir "${key_directory}"
fi

# Generate an ssh keypair with no password and place in files directory
if ssh-keygen -f "${private_key}" -P ""; then
  cat "${PWD}/files/ssh_key.pub"

  # Ensure restrictive permissions
  chmod 600 "${public_key}" "${private_key}"
fi
