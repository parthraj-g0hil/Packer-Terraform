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
  ami_name      = "Ubuntu-cis-lv1"
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
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # /var
  launch_block_device_mappings {
    device_name           = "/dev/sdb"
    volume_size           = 5
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # /tmp
  launch_block_device_mappings {
    device_name           = "/dev/sdc"
    volume_size           = 2
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # /var/log
  launch_block_device_mappings {
    device_name           = "/dev/sdd"
    volume_size           = 3
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # /var/tmp
  launch_block_device_mappings {
    device_name           = "/dev/sde"
    volume_size           = 3
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # /usr
  launch_block_device_mappings {
    device_name           = "/dev/sdf"
    volume_size           = 2
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # /var/log/audit
  launch_block_device_mappings {
    device_name           = "/dev/sdg"
    volume_size           = 3
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # /home
  launch_block_device_mappings {
    device_name           = "/dev/sdh"
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # swap
  launch_block_device_mappings {
    device_name           = "/dev/sdi"
    volume_size           = 5
    volume_type           = "gp3"
    delete_on_termination = true
  }

}
################################################################################################

build {
  name    = "ubuntu"
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    # Upload + run scripts with sudo bash
    execute_command = "echo 'ubuntu' | sudo -S bash '{{ .Path }}'"

    scripts = [
      # General scripts
      "scripts/packages-lib.sh",         
      "scripts/filesystem.sh",           
      "scripts/password-policy.sh",
      "scripts/disable-usb.sh",
      "scripts/grub.sh",
      "scripts/package-lock.sh",
      "scripts/CIS-fix.sh",
      "scripts/Hardening-Ubuntu-2024.sh",
      "scripts/ulimit.sh",
      "scripts/unwanted-users.sh",
      "scripts/version-hardening.sh",

      # CIS LEVEL 1 scripts
      "CIS-LEVEL-1/update.sh",
      "CIS-LEVEL-1/1.1.1.9.sh",
      "CIS-LEVEL-1/1.3.1.2.sh",
      "CIS-LEVEL-1/1.4.1.sh",
      "CIS-LEVEL-1/2.3.2.1-2.sh",
      "CIS-LEVEL-1/2.4.1.8.sh",
      "CIS-LEVEL-1/3.3.2.sh",
      "CIS-LEVEL-1/3.3.6.sh",
      "CIS-LEVEL-1/3.3.7.sh",
      "CIS-LEVEL-1/3.3.8.sh",
      "CIS-LEVEL-1/3.3.9.sh",
#      "CIS-LEVEL-1/4.2.3.sh",
#      "CIS-LEVEL-1/4.2.4.sh",
      "CIS-LEVEL-1/4.2.1-6-7.sh",
#      "CIS-LEVEL-1/4.3.4.sh",
#      "CIS-LEVEL-1/4.3.5.sh",
#      "CIS-LEVEL-1/4.3.8.sh",
#      "CIS-LEVEL-1/4.3.10.sh",
#      "CIS-LEVEL-1/4.4.1.1.sh",
#      "CIS-LEVEL-1/4.4.2.2.sh",
      "CIS-LEVEL-1/5.3.2.2.sh",
      "CIS-LEVEL-1/5.3.2.4.sh",
      "CIS-LEVEL-1/5.3.3.1.1.sh",
      "CIS-LEVEL-1/5.3.3.1.2.sh",
      "CIS-LEVEL-1/5.3.3.2.1.sh",
      "CIS-LEVEL-1/5.3.3.2.2.sh",
      "CIS-LEVEL-1/5.3.3.2.4.sh",
      "CIS-LEVEL-1/5.3.3.2.5.sh",
      "CIS-LEVEL-1/5.3.3.2.8.sh",
      "CIS-LEVEL-1/5.3.3.3.1-2.sh",
      "CIS-LEVEL-1/5.3.3.3.sh",
      "CIS-LEVEL-1/5.3.3.4.1.sh",
      "CIS-LEVEL-1/5.4.3.2.sh",
      "CIS-LEVEL-1/6.1.4.1.sh",
      "CIS-LEVEL-1/7.1.12.sh"
    ]
  }
}


################################################################################################
