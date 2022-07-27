no_auto_approve() {
  echo "
*******************************************************************************************
TERRAFORM_AUTO_APPROVE is false or has not been set and Terraform must be applied manually.
If you want to automate the next steps, enable it and recreate the container.
To continue the process use the following command but replace <container_name>
with the name of this container (default: automate_cloud_vpn):

docker exec -ti <container_name> terraform -chdir=/terraform apply

for example:
docker exec -ti automate-cloud-vpn terraform -chdir=/terraform apply

*******************************************************************************************
"

  exit 1
}

terraform -chdir=/terraform init
terraform -chdir=/terraform plan

# default to not auto-approve if env var is undefined
if [ -z "${TERRAFORM_AUTO_APPROVE}" ]; then
  no_auto_approve

elif [ "${TERRAFORM_AUTO_APPROVE}" = "true" ] ||
     [ "${TERRAFORM_AUTO_APPROVE}" = "True" ] ||
     [ "${TERRAFORM_AUTO_APPROVE}" = "TRUE" ] ||
     [ "${TERRAFORM_AUTO_APPROVE}" = "1" ] ; then

  terraform -chdir=/terraform apply -auto-approve

elif [ "${TERRAFORM_AUTO_APPROVE}" = "false" ] ||
     [ "${TERRAFORM_AUTO_APPROVE}" = "False" ] ||
     [ "${TERRAFORM_AUTO_APPROVE}" = "FALSE" ] ||
     [ "${TERRAFORM_AUTO_APPROVE}" = "0" ] ; then

  no_auto_approve

else
  echo "Unknown value for TERRAFORM_AUTO_APPROVE: '${TERRAFORM_AUTO_APPROVE}'. Assuming default: 'false'"
  no_auto_approve

fi
