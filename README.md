# automate-cloud-vpn
Automate the deployment of a cloud instance using Terraform and Ansible and create a VPN server for remote access
e automated build processing is enabled.

## Table of Contents
- [Pre-requisites](#pre-requisites)
- [Quickstart](#quickstart)
- [Process Rundown](#process-rundown)
- [Building Images](#building-images)
  - [Testing Images](#testing-images)

## Pre-requisites
- Must have a basic understanding of Ansible, Docker, and Terraform
- Docker must be installed on the host machine.
- You must create or have access to an AWS account

## Quickstart
#### 1. Clone the repository
```
git clone https://github.com/albeanski/automate-cloud-vpn/ .
```

#### 2. Create an `env_vars` file to store required variables the container needs.
```
nano env_vars
```
**./env_vars**
```bash
AWS_INSTANCE_NAME=automate_cloud_vpn                      # The name of the ec2 instance that will be created. Also creates a tag on the instance: Name=$AWS_INSTANCE_NAME 
AWS_INSTANCE_AMI=ami-abcdefg1234567890                    # The ami id to attach use for the instance
AWS_ACCESS_KEY=ABCDEFGHIJK123456789                       # The AWS access key
AWS_SECRET_KEY=ZYXWVUTSRQP987654321                       # The AWS secret key
AWS_REGION=us-east-1                                      # The region to create the instance in
AWS_USER=ubuntu                                           # The privileged username to use to ssh into the instance
```
Edit the env_vars file with your information and save.

#### 3. Create an empty `terraform.tfstate` terraform state file. This will allow you to persist the terraform state after destruction.
```
touch terraform.tfstate
```
Then add a bind mount to the docker-compose file:
**./docker-compose.yml**
```
  ...
  volumes:
    - ./terraform.tfstate:/terraform/terraform.tfstate
  ...
```
(Or if you have a terraform state already that you want to use bind that .tfstate file to `/terraform/terraform.state`)

#### 4. Generate ssh keys
Use the `generate_ssh_keys.sh` script to create ssh keys that terraform and ansible will use.
```
./generate_ssh_keys.sh
```

#### 5. Run docker-compose in detached mode using: 
```
docker-compose up -d
```
To follow the logs as the container is created and set up use:
`docker logs -f <container_name>`
So in the case of the included docker-compose file:
`docker logs -f automate-cloud-vpn`

The container should do all the setup and installation automatically. However, if you need to test out new scripts
or configurations, move on to the following section.

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
./dockerfiles/build-image.sh ./dockerfiles/ansible-terraform-aws/
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
The build-image script can be automated with the following environment variables:
DOCKER_REMOTE_USER - The script will automatically set the remote user and won't ask for it. 
BUILD_IMAGE_PUSH - The script will automatically push to the remote repository.
