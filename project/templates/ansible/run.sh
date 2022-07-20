#!/bin/sh
# Runs a playbook with all the preset args
cd "{{ project_dir }}" && \
#ansible-playbook import_playbook.yml \
ansible-playbook ${1} \
    --inventory inventory/ \
    --inventory {{ tf_post_apply_inventory_path }} \
    --private-key={{ ssh_private_key }} \
    --user {{ aws_user }} \
    --limit localhost,tag_Name_{{ aws_instance_name }} \
#    --extra-vars "import_playbook={{ ansible_runtime_dir }}/${1}"
