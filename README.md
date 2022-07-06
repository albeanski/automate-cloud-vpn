# automate-cloud-vpn
Automate the deployment of a cloud instance using Terraform and Ansible and create a VPN server for remote access

## Configuring environment
### Install hooks
Install git hooks to ensure automated build processing is enabled.

```
./install_hooks
```

## Building Dockerfiles
Use the image builder script to automate image tagging.

```
./build/build.sh
```

The build script automatically increments the image versions using `Dockerfile.<image_name>.version`
using git hooks. For this reason, be sure to disable fast-forward when merging to main and dev 
(see `git_merge_dev.sh`).
If no version file exists, it will create one with a 0.0.1 version.
Version numbering is based on commits of modified Dockerfiles and the current branch.
*Major* versions are incremented after merging to main, *minor* increments occurs after merging to dev,
commits to any other branch increments the *patch* version.
