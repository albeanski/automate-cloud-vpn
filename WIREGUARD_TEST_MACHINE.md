# Wireguard Client Testing on Baremetal/Virtual Machine

This guide is for setting up the docker host to test the wireguard connection 
to the AWS instance, if you want to use a docker container for testing instead,
refer the [quickstart guide](quickstart).

This should also work with separate machine as well if you copy the wireguard config
to it.

---
## Table of Contents
- [Pre-requisites](#pre-requisites)
- [Start](#start)
- [Testing Wireguard Connection](#testing-wireguard-connection)
---

## Pre-requisites
- Must have a basic understanding of Ansible, Docker, and Terraform
- Docker-engine and docker-compose must be installed on the host machine.
- You must create or have access to an AWS account

---
## Start
#### 1. Clone the repository
```
git clone https://github.com/albeanski/automate-cloud-vpn/ .
```

Change directory into the cloned repository:
```
cd automate-cloud-vpn
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

#### 3. Volume Mounts
Create an empty `terraform.tfstate` terraform state file. This will allow you to persist the terraform state after destruction.
```
touch terraform.tfstate
```
Then add a bind mount to the docker-compose file:
**./docker-compose.yml**
```yaml
  ...
  volumes:
    - ./terraform.tfstate:/terraform/terraform.tfstate
  ...
```
(Or if you have a terraform state already that you want to use bind that .tfstate file to `/terraform/terraform.state`)

#### 4. SSH keys
SSH keys will be created during the automation process. To provide your own, create an `ssh_keys` directory on the repo root:
```
mkdir ./ssh_keys
```

The expected names in the `ssh_keys` directory are: `ssh_key` and `ssh_key.pub` where `ssh_key` is the private key and `ssh_key.pub` is
the public key.

```
ssh_keys/
├── ssh_key
└── ssh_key.pub
```

If you leave the `ssh_keys` directory empty, ssh_keys will be generated inside that directory.

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
```yaml
  ...
  environment:
    - TERRAFORM_AUTO_APPROVE=true
  ...
```
Now the entire automation process will complete when creating the container, and no more user
interaction is required. 
 
#### 6. Docker-compose
We will be using docker-compose to spin up our containers. There are 2 containers in this deployment:
app: the automation container
testing: a container with wireguard to test the connection to the server

We will use the testing compose file as an override:

```
docker-compose up -d
```

To follow the logs as the container is created and set up use:
`docker logs -f <container_name>`
So in the case of the included docker-compose file:
`docker logs -f automate-cloud-vpn`

The container should do all the setup and installation automatically. However, if you would like
to test out the connection to the server, follow the next steps.

#### 7. Install wireguard on the client machine
In order to test the wireguard connection we need another machine as the client. For simplicity, we will use the docker host machine as the client. The following installs onto Ubuntu and will likely work on other Debian based operating systems (see the [wireguard installation](www.wireguard.com/install)  documentation for your specific OS).

Update the apt repository & Install the wireguard package
```bash
sudo apt update
sudo apt install -y wireguard
```

#### 8. Setup and configure wireguard on the client

Copy the client private and public wireguard keys as well as the wg0 interface config.
> Use the `fetch_wireguard_files.sh` script to do this for you. `sudo ./fetch_wireguard_files.sh`

```bash
docker exec -it automate-cloud-vpn cat /wireguard/client/private_key > /etc/wireguard/privatekey
docker exec -it automate-cloud-vpn cat /wireguard/client/private_key > /etc/wireguard/publickey
docker exec -it automate-cloud-vpn cat /wireguard/client/wg0.conf > /etc/wireguard/wg0.conf
```

#### 9. Testing Wireguard Connection
To test the wireguard connection we must create and spin up the wireguard interface on the host. 
We do this by running `wg-quick` on the wg0 interface:

```bash
sudo wg-quick up wg0
```

Once the interface has been created, it will automatically ping the wireguard server on the AWS instance 
on the wireguard subnet. The default value should be 10.11.12.1 unless it was overridden with the 
`WIREGUARD_SERVER_IP` environment variable. The output should be similar to the following if everything
was successful:
```
[#] ip link add wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.11.12.2/24 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] ping -c 3 10.11.12.1
PING 10.11.12.1 (10.11.12.1): 56 data bytes
64 bytes from 10.11.12.1: seq=0 ttl=64 time=77.870 ms
64 bytes from 10.11.12.1: seq=1 ttl=64 time=32.076 ms
64 bytes from 10.11.12.1: seq=2 ttl=64 time=26.453 ms

--- 10.11.12.1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 26.453/45.466/77.870 ms
```

---
### Interactive Terraform Apply
If TERRAFORM_AUTO_APPROVE is unset or set to false, `terraform apply` must be run manually after 
spinning up the container.

First make sure `terraform plan` has completed. Check the logs to confirm:
```bash
docker logs -f automate_cloud_vpn
```

If `terraform plan` has completed, the output should be similar to the following:
```
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

This will begin the creation of the AWS instance and the rest of the
automation process will continue as normal.
