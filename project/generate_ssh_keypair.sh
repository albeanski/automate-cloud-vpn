#/bin/sh
private_key="${PWD}/files/ssh_key"
public_key="${private_key}.pub"


# Generate an ssh keypair with no password and place in files directory
if ssh-keygen -f "${private_key}" -P ""; then
  cat "${PWD}/files/ssh_key.pub"

  # Ensure restrictive permissions
  chmod 600 "${public_key}" "${private_key}"
fi
