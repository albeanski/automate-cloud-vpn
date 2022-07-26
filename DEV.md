# Development Guide

This document is to guide this project's development. This is a good place to start when writing
any new code.

## Table of Contents
- [Process Rundown](#process-rundown)
- [Building Images](#building-images)
  - [Testing Images](#testing-images)
- [Terraform](#terraform)
  - [Testing Terraform](#testing-terraform)
  

## Process Rundown
### entrypoint.sh
The container first runs the `entrypoint.sh` script. It will install any dependencies for ansible and python 
defined in `requirements.yml` and  `pip_requirements.txt` respectively. Then runs the entrypoint.yml playbook.

### entrypoint.yml
The entrypoint.yml playbook runs the inital setup. It will create all necessary ansible and terraform files and 
scripts. Then builds and runs the terraform config using the `terraform_build.sh` script.

### terraform_build.sh
This script runs the terraform init, plan, and apply commands to spin up the new instance. If the configuration  has 
no errors, main.tf runs a local-exec playbook after creation. 

### setup.yml
The setup.yml playbook does the package installation and configuration. If you look closely, the teraform local-exec
does not run ansible-playbook dieextly, but the `/ansible/run.sh` script with `setup.yml` as the only argumebt. run.sh 
then calls an ansible-playbook with the appropriate inventory, ssh key, and ssh user and passes the first argument
to a call to `ansible-playbook ... --extra-args "import_playbook=$1"` import_playbook.yml. This is necessaey to separate
the project/ directory with the sensitive templated config files.

## Building Images
Dockerfiles can be found in the `./dockerfiles` directory with the name of the image as the subdirectory. There is a `build-image.sh` included
to simplify the build process.
### build-image.sh
When building an image, make sure the appropriate version is set. The version can be found in the `version` file inside the dockerfile directory.
To build an image:
```
./dockerfiles/build-image.sh ${dockerfile_directory}
```
So for example:
```
./dockerfiles/build-image.sh ./dockerfiles/ansible-terraform-aws
```

This will begin the image building process. First the script will run
```
docker build -t ${image_name}:${version} -t ${image_name}:${latest} ${1}
```
Which looks at the parent directory for the `${image_name}` and `${version}` is taken from the contents of the `version` file. Once the build process is complete, it will attempt to test the image. The process of testing is outlined below.

### Testing images
To test an image after a build, create a `test-image.sh` file inside the directory containing the Dockerfile and it will be ran after an image build.
The build-image.sh script is run as follows: `test-image`

### build-image.sh environment variables
The build-image script can be automated with the following environment variables: \
`DOCKER_REMOTE_USER` - The script will automatically set the remote user to this environment variable's value and won't ask for it. \
`BUILD_IMAGE_PUSH` - The script will automatically push to the remote repository (accepted values: true, false).
To run the script using these environment variables:
```
DOCKER_REMOTE_USER=myremoteuser BUILD_IMAGE_PUSH=true ./dockerfiles/build-image.sh ./dockerfiles/ansible-terraform-aws
```

## Terraform
### Testing Terraform
Be sure to keep the terraform state saved locally using a bind mount on the local disk. This
will prevent name conflicts when changing config and recreating the container.
```yaml
...
  volumes:
    - ./terraform.tfstate:/terraform/terraform.tfstate
...
```

When testing fresh configs, be sure to destroy the old one.
```bash
docker exec -ti automate-cloud-vpn terraform -chdir=/terraform destroy
```

Type 'yes' to confirm the deatruction.
