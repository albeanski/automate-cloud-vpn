# automate-cloud-vpn
Automate the deployment of a cloud instance using Terraform and Ansible and create a VPN server for remote access
e automated build processing is enabled.

## Building Dockerfiles
Use the image builder script to automate image tagging.

```
build-image.sh [directory containing Dockerfile]

examples:

./dockerfiles/build-image.sh ./dockerfiles/ansbile-terraform/

```

### Testing images
To test an image after a build, create a `test-image.sh` file inside the directory containing the Dockerfile and it will be ran after an image build.
The build-image.sh script is run as follows: `test-image`


## Quickstart
### Required environment variables
There are a few ways to configure the container, but the simplest is to set the appropriate environment variables. In this example, we will use an `env_vars` file
to set the environment variables the container needs to run.
env_vars
```
AWS_INSTANCE_NAME=automate_cloud_vpn                      # The name of the ec2 instance that will be created. Also creates a tag on the instance: Name=$AWS_INSTANCE_NAME 
AWS_INSTANCE_AMI=ami-abcdefg1234567890                    # The ami id to attach use for the instance
AWS_ACCESS_KEY=ABCDEFGHIJK123456789                       # The AWS access key
AWS_SECRET_KEY=ZYXWVUTSRQP987654321                       # The AWS secret key
AWS_REGION=us-east-1                                      # The region to create the instance in
AWS_USER=ubuntu                                           # The privileged username to use to ssh into the instance
```

### Terraform state
To persist the terraform state after destruction, first create a blank `terraform.tfstate` file.
`touch terraform.tfstate`
Then add a bind mount to the docker-compose file:
```
  ...
  volumes:
    - ./terraform.tfstate:/terraform/terraform.tfstate
  ...
```

Or if you have a terraform state already that you want to use bind that .tfstate file to `/terraform/terraform.state`

### Docker-compose
Run docker-compose in detached mode using: 
`docker-compose up -d`
To follow the logs as the container is created and set up use:
`docker logs -f <container_name>`
So in the case of the included docker-compose file:
`docker logs -f automate-cloud-vpn`

The container should do all the setup and installation automatically. Howevee, if you need to test out new scripts
or configurations, move on to the following section.

## Process Rundown
### entrypoint.sh
The container first runs the `entrypoint.sh` script. It will install any dependencies for ansible and python 
defined in `requirements.yml` and  `pip_requirements.txt` respectively. Then runs the entrypoint.yml playbook.

### entrypoint.yml
The entrypoint.yml playbook runs the inital setup. It will create all necessary ansible and terraform files and 
scripts. Then builds and runs the terraform config using the `terraform_build.sh` script.

### terraform_build.sh
This script runs the terraform init, plan, and apply commands to spin uo the new instance. If the configuration  has 
no errors, main.tf runs a local-exec playbook after creation. 

### setup.yml
The setup.yml playbook does the package installation and configuration. If you look closely, the teraform local-exec
does not run ansible-playbook dieextly, but the `/ansible/run.sh` script with `setup.yml` as the only argumebt. run.sh 
then calls an ansible-playbook with the appropriate inventory, ssh key, and ssh user and passes the first argument
to a call to `ansible-playbook ... --extra-args "import_playbook=$1"` import_playbook.yml. This is necessaey to separate
the project/ directory with the sensitive templated config files.

