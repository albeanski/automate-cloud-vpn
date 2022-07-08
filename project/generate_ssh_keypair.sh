#/bin/sh
# Generate an ssh keypair with no password and place in files directory
ssh-keygen -f "${PWD}/files/ssh_key" -P ""
cat "${PWD}/files/ssh_key.pub"
