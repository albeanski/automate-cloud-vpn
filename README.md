# automate-cloud-vpn
Automate the deployment of a cloud instance using Terraform and Ansible and create a VPN server for remote access
e automated build processing is enabled.

> See the [development documentation](DEV.md) for more information.

---
## Table of Contents
- [Pre-requisites](#pre-requisites)
- [Quickstart](#quickstart)
- [Testing Wireguard Connection](#testing-wireguard-connection)

---
## Pre-requisites
- Must have a basic understanding of Ansible, Docker, and Terraform
- Docker engine and docker-compose must be installed on the host machine.
- You must create or have access to an AWS account

---
## Quickstart
> This uses a separate container as a testing container to test the connection to the wireguard server
on the AWS instance. If you want to use the docker host as the wireguard client for testing instead,
follow the [Wireguard Client on Machine](WIREGUARD_TEST_MACHINE.md) guide.

#### 1. Clone the repository
```
git clone https://github.com/albeanski/automate-cloud-vpn/ .
```

And change directory into the cloned repository
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

Restrict permissions of `env_vars` to user only:
```
chmod 660 env_vars
```

#### 3. Volume Mounts
Create an empty `terraform.tfstate` terraform state file. This will allow you to persist the terraform state after destruction.
```
touch terraform.tfstate
```

This terraform state file has a bind mount in the docker-compose file:

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

We will use the testing compose file as an override as follows:

```
docker-compose -f docker-compose.yml -f docker-compose-testing.yml up -d
```

To follow the logs as the container is created and set up use:
`docker logs -f <container_name>`
So in the case of the included docker-compose file:
`docker logs -f automate-cloud-vpn`

The container should do all the setup and installation automatically.

#### Final notes
When the automation process is complete you should see these two lines in the logs:
```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
Creating endless sleep loop to persist container. Press CTRL+C to exit
```

You should now have a new aws instance with wireguard installed and configured as the server as
well as a client side installation of wireguard on a separate container as the client. To test
if everything is working correctly, see below.

---
### Testing Wireguard Connection
To test the wireguard connection we must create and spin up the wireguard interface on the testing
container. We do this by running `wg-quick` on the wg0.conf file in the shared config directory. 
(this file was created by ansible on the app container):

```
docker exec automate-cloud-vpn-testing wg-quick up /wireguard/wg0.conf
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
