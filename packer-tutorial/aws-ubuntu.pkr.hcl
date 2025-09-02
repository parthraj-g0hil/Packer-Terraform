/*The packer {} block contains Packer settings, including specifying a required Packer version

In addition, you will find "required_plugins" block in the Packer block, which specifies all the 
plugins required by the template to build your image.

The source attribute is only necessary when requiring a plugin outside the HashiCorp domain
*/
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

/*Source blocks use builders and communicators to define what kind of virtualization to use, 
how to launch the image you want to provision, and how to connect to it. 

Builders and communicators are bundled together and configured side-by-side in a source block
and you can use multiple sources in a single build.

A source block has two important labels: a builder type and a name. 
These two labels together will allow us to uniquely reference sources later on when we define build runs.

In the example template, the builder type is amazon-ebs and the name is ubuntu.

Each builder has its own unique set of configuration attributes. The amazon-ebs builder launches the source AMI,

In the example template, the amazon-ebs builder configuration launches a t2.micro AMI in the us-west-2 region using an ubuntu-jammy AMI as the base image, then creates an image named learn-packer-linux-aws from that instance.


*/
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


/*The build block defines what Packer should do with the EC2 instance after it launches.

In the example template, the build block references the AMI defined by the source block above (source.amazon-ebs.ubuntu).
*/
build {
  name = "learn-packer"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
}



/*Authenticate to AWS
export AWS_ACCESS_KEY_ID="<YOUR_AWS_ACCESS_KEY_ID>"
export AWS_SECRET_ACCESS_KEY="<YOUR_AWS_SECRET_ACCESS_KEY>"
*/

#Initialize Packer configuration

#packer init .


/*Format and validate your Packer template
Format your template. Packer will print out the names of the files it modified, if any. In this case, your template file was already formatted correctly, so Packer won't return any file names.

packer fmt .

You can also make sure your configuration is syntactically valid and internally consistent by using the "packer validate" command.

packer validate .
*/



/*Build Packer image

Build the image with the "packer build" command.

packer build aws-ubuntu.pkr.hcl

*/