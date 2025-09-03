# Packer Configuration Guide

## Packer Block

The `packer {}` block contains Packer settings, including specifying a
required Packer version.

In addition, you will find the **`required_plugins`** block in the
Packer block, which specifies all the plugins required by the template
to build your image.

The `source` attribute is only necessary when requiring a plugin outside
the HashiCorp domain.

``` hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}
```

------------------------------------------------------------------------

## Source Block

Source blocks use **builders** and **communicators** to define what kind
of virtualization to use, how to launch the image you want to provision,
and how to connect to it.

-   Builders and communicators are bundled together and configured
    side-by-side in a source block.\
-   You can use multiple sources in a single build.

A source block has two important labels:\
- A **builder type**\
- A **name**

These two labels together uniquely reference sources later when we
define build runs.

In this example, the builder type is **amazon-ebs** and the name is
**ubuntu**.

The `amazon-ebs` builder launches the source AMI. Here, it launches a
`t2.micro` AMI in the `ap-south-1` region using an Ubuntu 24.04 AMI as
the base image, then creates an AMI named `learn-packer-linux-aws`.

``` hcl
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
}
```

------------------------------------------------------------------------

## Build Block

The build block defines what Packer should do with the EC2 instance
after it launches.

In this example, the build block references the AMI defined by the
source block above (`source.amazon-ebs.ubuntu`).

``` hcl
build {
  name = "learn-packer"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
}
```

------------------------------------------------------------------------

## AWS Authentication

Before running Packer, authenticate to AWS:

``` bash
export AWS_ACCESS_KEY_ID="<YOUR_AWS_ACCESS_KEY_ID>"
export AWS_SECRET_ACCESS_KEY="<YOUR_AWS_SECRET_ACCESS_KEY>"
```

------------------------------------------------------------------------

## Initialize Packer

``` bash
packer init .
```

------------------------------------------------------------------------

## Format and Validate Packer Template

Format your template:

``` bash
packer fmt .
```

Validate configuration:

``` bash
packer validate .
```

------------------------------------------------------------------------

## Build Packer Image

Build the image with the command:

``` bash
packer build aws-ubuntu.pkr.hcl
```

------------------------------------------------------------------------

## Provisioning

Provisioners automate software installation and configuration before
turning a machine into an image.

In this tutorial, Redis is installed.

### Example Provisioner

This shell provisioner:\
- Sets an environment variable `FOO`\
- Waits 30 seconds\
- Installs Redis\
- Creates a file `example.txt` with the value of `FOO`

``` hcl
provisioner "shell" {
  environment_vars = [
    "FOO=hello world",
  ]
  inline = [
    "echo Installing Redis",
    "sleep 30",
    "sudo apt-get update",
    "sudo apt-get install -y redis-server",
    "echo "FOO is $FOO" > example.txt",
  ]
}
```

### Example file (installing nginx)
``` hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "learn-packer-linux-aws-nginx"
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
}

  ami_tags = {
    Name = "packer-nginx"
  }


build {
  name    = "learn-packer"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    environment_vars = [
      "FOO=hello world",
    ]
    inline = [
      "echo Installing Nginx",
      "sleep 30",
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "echo \"FOO is $FOO\" > example.txt",
    ]
  }
}
```