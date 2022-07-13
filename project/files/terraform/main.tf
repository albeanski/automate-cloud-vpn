# Adapted from: https://komport.medium.com/playing-with-terraform-ansible-and-aws-creating-simple-web-app-dbe5143747df

#Terraform main config file
#Defining access keys and region
provider "aws" {
  region     = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

# Selecting default VPC. In the next block we will attach this VPC to the security groups.
data "aws_vpc" "selected" {
  default = true
}

{% for security_group in aws_security_groups %}
resource "aws_security_group" "{{ security_group.id }}" {
  name        = "{{ security_group.name }}"
  description = "{{ security_group.description | default('Security Group') }}"
  vpc_id      = "${data.aws_vpc.{{ security_group.vpc | default('selected') }}.id}" #Default VPC id here

{% for ingress in security_group.ingresses %} 
  #{{ ingress.name }}
  ingress {
    from_port   = {{ ingress.from_port }}
    to_port     = {{ ingress.to_port }}
    protocol    = "{{ ingress.protocol }}"
    cidr_blocks = ["{{ ingress.cidr_blocks | default(['0.0.0.0/0']) | join('\", \"') }}"]
  }

{% endfor %}
{% for egress in security_group.egresses | default([{}]) %} 
  egress  {  # Outbound all allow
    from_port   = {{ egress.from_port | default(0) }}
    to_port     = {{ egress.to_port | default(0) }}
    protocol    = {{ egress.protocol | default(-1) }}
    cidr_blocks = ["{{ ingress.cidr_blocks | default(['0.0.0.0/0']) | join('\", \"') }}"]
  }

{% endfor %}
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "${file(var.ssh_public_key)}"
}

{% endfor %}
resource "aws_instance" "{{ instance_id | default('instance') }}" {
  ami                    = "${var.instance_ami}"              #AMI defined in variables.tf file
  instance_type          = "${var.instance_type}"             #Instance type defined in variables.tf file
  key_name               = "${aws_key_pair.deployer.key_name}"              #KeyPair name to be attached to the instance. Forgot to add in variables :D
  vpc_security_group_ids = [{% for sg in aws_security_groups %}"${aws_security_group.{{ sg.id }}.id}"{{ ',' if loop.index < loop.length else '' }}{% endfor %}]    #Security group id which we already created

  #Because AWS instance needs some time to be ready for usage we will use below trick with remote-exec. 
  #As per documentation remote-exec waits for successful connection and only after this runs command. 
  provisioner "remote-exec" {
    inline = ["sudo hostname"]

    connection {
      type        = "ssh"
      user        = "${var.instance_username}"
      private_key = "${file(var.ssh_private_key)}"
      host        = "${self.public_ip}"
    }
  }
  
  #local-exec runs our app server related playbook
  provisioner "local-exec" {
    command ="cd {{ ansible_project_path | default('/project') }} && ansible-playbook {{ ansible_playbook_init | default('init.yml') }} --private-key=${var.ssh_private_key} --user ${var.instance_username}"
  }
}
