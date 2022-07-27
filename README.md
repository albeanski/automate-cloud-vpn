# automate-cloud-vpn
Automate the deployment of a cloud instance using Terraform and Ansible and create a VPN server for remote access
e automated build processing is enabled.

See the [development documentation](DEV.md) for more information.

## Table of Contents
- [Pre-requisites](#pre-requisites)
- [Quickstart](#quickstart)

## Pre-requisites
- Must have a basic understanding of Ansible, Docker, and Terraform
- Docker must be installed on the host machine.
- You must create or have access to an AWS account
- A wireguard client machine to test the connection. This can be another workstation/vm/machine or the docker host itself.

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
See [ENV.md](ENV.md) for a full list of environment variables the container accepts.

#### 3. Create an empty `terraform.tfstate` terraform state file. This will allow you to persist the terraform state after destruction.
```
touch terraform.tfstate
```
Then add a bind mount to the docker-compose file:
**./docker-compose.yml**
```yanl
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

#### 5. Enable Terraform Auto Approve
When using the Terraform apply command normally, the following interactive confirmation is 
prompted:
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```
This allows you to review the configuration changes before it is deployed. However, we will enable 
auto-approve to skip this prompt. See [Interactive Terraform Apply](#interactive-terraform-apply)
if you want to review and apply the terraform configuration manually.

Set the `TERRAFORM_AUTO_APPROVE` environment variable in the docker-compose file to 'true':
```yanl
  ...
  environment:
    - TERRAFORM_AUTO_APPROVE=true
  ...
```

#### 6. Run docker-compose in detached mode using: 
```
docker-compose up -d
```
To follow the logs as the container is created and set up use:
`docker logs -f <container_name>`
So in the case of the included docker-compose file:
`docker logs -f automate-cloud-vpn`

The container should do all the setup and installation automatically. However, if you need to test out new scripts
or configurations, move on to the following section.

#### 7. Install wireguard on the client machine
In order to test the wireguard connection we need another machine as the client. For simplicity, we will use the docker host machine as the client. The following installs onto Ubuntu and will likely work on other Debian based operating systems (see the [wireguard installation](www.wireguard.com/install)  documentation for your specific OS).

Update the apt repository & Install the wireguard package
```bash
sudo apt update
sudo apt install -y wireguard
```

#### 8. Setup and configure wireguard on the client

Copy the client private and public wireguard keys as well as the wg0 interface config.
> Use the `fetch_wireguard_files.sh` script to do this for you. `./fetch_wireguard_files.sh`

```bash
docker exec -it automate-cloud-vpn cat /wireguard/client_private_key > /etc/wireguard/privatekey
docker exec -it automate-cloud-vpn cat /wireguard/client_private_key > /etc/wireguard/publickey
docker exec -it automate-cloud-vpn cat /wireguard/client_wg0.conf > /etc/wireguard/wg0.conf
```

Quick start wireguard using wg0
```bash
wg-quick up wg0
```

#### Final notes
You should now have a new aws instance with wireguard installed and configured as
well as a client side installation of wireguard on your local machine. Ping the 
aws instance on the wireguard subnet. The default value should be 10.11.12.1 unless
you overrode it with the `WIREGUARD_SERVER_IP` environment variable.

```bash
ping 10.11.12.1
```


### Interactive Terraform Apply
If TERRAFORM_AUTO_APPROVE is unset or set to false, `terrform` apply must be run manually after 
spinning up the container.

First make sure `terraform plan` has completed. Check the logs to confirm:
```bash
docker logs -f automate_cloud_vpn
```

If `terraform plan` has completes, the output should be similar to the following:
```bash
*******************************************************************************************
TERRAFORM_AUTO_APPROVE is false or has not been set and Terraform must be applied manually.
If you want to automate the next steps, enable it and recreate the container.
To continue the process use the following command but replace <container_name>
with the name of this container (default: automate_cloud_vpn):

docker exec -ti <container_name> terraform -chdir=/terraform apply

for example:
docker exec -ti automate-cloud-vpn terraform -chdir=/terraform apply

*******************************************************************************************

Creating endless sleep loop to persist container. Press CTRL+C to exit
```

Copy the docker exec command and run it:
```
docker exec -ti automate-cloud-vpn terraform -chdir=/terraform apply
```
