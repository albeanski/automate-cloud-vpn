variable "ssh_public_key" {
  default     = "{{ ssh_public_key | default('project/files/ssh_key.pub') }}"
  description = "Public key for ssh"
}

variable "ssh_private_key" {
  default     = "{{ ssh_private_key | default('project/files/ssh_key') }}"
  description = "Private key for ssh"
}

variable "instance_name" {
  default     = "{{ aws_instance_name | mandatory }}"
  description     = "Adds a tag of name=instance_name"
}

variable "instance_type" {
  default     = "{{ aws_instance_type | default('t2.micro') }}"
  description     = "Instance type"
}

variable "access_key" {
  default     = "{{ aws_access_key }}"
  description     = "IAM Access Key"
}

variable "secret_key" {
  default     = "{{ aws_secret_key }}"
  description = "IAM Secret Key"
}

variable "instance_ami" {
  default     = "{{ aws_instance_ami }}"
  description = "AMI"
}

variable "region" {
  default     = "{{ aws_region }}"
  description = "AWS Region"
}

variable "instance_username" {
  default     = "{{ instance_username | default('ubuntu') }}"
}
