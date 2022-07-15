ready=0
while [ "${ready}" -eq 0 ]; do
  echo "Waiting for /runtime/.entrypoint_complete..." 2>&1
  if [ -f "/runtime/.entrypoint_complete" ]; then
    ready=1
  else
    sleep 5
  fi
done

terraform -chdir=/runtime/terraform/ init
terraform -chdir=/runtime/terraform plan
terraform -chdir=/runtime/terraform apply -auto-approve
