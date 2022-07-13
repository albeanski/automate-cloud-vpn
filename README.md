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

## Testing images
To test an image after a build, create a `test-image.sh` file inside the directory containing the Dockerfile and it will be ran after an image build.
The build-image.sh script is run as follows: `test-image`
