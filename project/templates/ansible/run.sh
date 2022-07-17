#!/bin/sh
# Runs a p
cd "{{ project_dir }}" && \
ansible-playbook import_playbook.yml \
    --inventory {{ tf_post_apply_inventory_path }} \
    --private-key={{ ssh_private_key }} \
    --user {{ aws_user }} \
    --extra-vars "import_playbook={{ ansible_runtime_dir }}/${1}"
