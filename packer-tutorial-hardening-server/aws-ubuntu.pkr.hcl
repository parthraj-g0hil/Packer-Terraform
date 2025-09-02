################################################################
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}
################################################################










################################################################
source "amazon-ebs" "ubuntu" {
  ami_name      = "learn-packer-linux-aws"
  instance_type = "t2.micro"
  region        = "ap-south-1"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  ssh_username = "ubuntu"

  ami_tags = {
    Name = "packer-nginx-hardened"
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/sdb"
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/sdc"
    volume_size           = 5
    volume_type           = "gp3"
    delete_on_termination = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/sdd"
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/sde"
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/sdf"
    volume_size           = 5
    volume_type           = "gp3"
    delete_on_termination = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/sdg"
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/sdh"
    volume_size           = 15
    volume_type           = "gp3"
    delete_on_termination = true
  }
}
################################################################################################









################################################################################################
build {
  name    = "learn-packer"
  sources = ["source.amazon-ebs.ubuntu"]

  # Upload all scripts from local dir -> /tmp/Hardening-scripts in instance
  provisioner "file" {
    source      = "/home/dell/DEVOPS/Server-hardening/Hardening-scripts"
    destination = "/tmp/Hardening-scripts"
  }

  # Run all scripts in sequence
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/Hardening-scripts/*.sh",
      "for script in /tmp/Hardening-scripts/*.sh; do echo Running $script; sudo bash $script; done"
    ]
  }
}
################################################################################################
