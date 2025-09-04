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

source "amazon-ebs" "ubuntu" {
  ami_name      = "packer-ubuntu-harden-4"
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

  # Root disk
  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 25
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # /var
  launch_block_device_mappings {
    device_name           = "/dev/sdb"
    volume_size           = 15
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # /tmp
  launch_block_device_mappings {
    device_name           = "/dev/sdc"
    volume_size           = 5
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # /var/log
  launch_block_device_mappings {
    device_name           = "/dev/sdd"
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # /var/tmp
  launch_block_device_mappings {
    device_name           = "/dev/sde"
    volume_size           = 6
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # /usr
  launch_block_device_mappings {
    device_name           = "/dev/sdf"
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # /var/log/audit
  launch_block_device_mappings {
    device_name           = "/dev/sdg"
    volume_size           = 7
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # /home
  launch_block_device_mappings {
    device_name           = "/dev/sdh"
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # swap
  launch_block_device_mappings {
    device_name           = "/dev/sdi"
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true
  }

}
################################################################################################

build {
  name    = "ubuntu"
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    # Upload + chmod + run with sudo bash
#    execute_command = "echo 'ubuntu' | sudo -S bash -c 'chmod +x {{ .Path }} && {{ .Path }}'"
    execute_command = "echo 'ubuntu' | sudo -S bash '{{ .Path }}'"
    scripts = [
      "scripts/packages-lib.sh",         
      "scripts/filesystem2.sh",           
      "scripts/password-policy.sh",
      "scripts/disable-usb.sh",
      "scripts/firewall.sh",
      "scripts/grub.sh",
      "scripts/package-lock.sh",
      "scripts/CIS-fix.sh",
      "scripts/Hardening-Ubuntu-2024.sh",
      "scripts/time-sync.sh",
      "scripts/ulimit.sh",
      "scripts/unwanted-users.sh",
      "scripts/version-hardening.sh",
    ]
  }
}

################################################################################################
