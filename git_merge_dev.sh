#!/bin/bash

cur_branch=$(git branch --show-current)

merge() {
  branch="${1}"
  git checkout dev
  git merge --no-ff "${branch}"
}

if [ "${cur_branch}" = "dev" ]; then
  read -p "Enter branch to merge into dev: " cur_branch
fi

read -p "Merge ${cur_branch} to dev? [y/n]" confirm_merge
if [ "${confirm_merge}" = "y" ]; then
  merge "${cur_branch}"
  read -p "Push to remote? [y/n]" confirm_push
  if [ "${confirm_push}" = "y" ]; then
    git push
  fi

  read -p "Delete ${cur_branch} branch? [y/n]" confirm_del
  if [ "${confirm_del}" = "y" ]; then
    read -p "Delete remote branch? [y/n]" confirm_del_remote
    if [ "${confirm_del_remote}" = "y" ]; then
      git push origin --delete "${cur_branch}"
    fi
    git branch -d "${cur_branch}"
  fi
fi

