
provider "aws" {
    region = "eu-west-2"
}


variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable availability_zone {}
variable env_prefix {} // can be either dev, prod or staging etc. 
variable my_ip {}
variable instance_type {}
variable public_key_location {}
variable image_name {}
variable ssh_key_private {}


resource "aws_vpc" "myapp-vpc" { // aws_vpc is 'provider_resource' and development-vpc is the 
    // resource like a variable name
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc" // as the variable is being used inside a string, 
        // it has a different script with brackets and $
    }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id // as the vpc above doesnt exist yet, so use resource.variable.id to get its id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.availability_zone// region has 3 AZs, so just chose one
    tags = {
        Name: "${var.env_prefix}-subnet"
    }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name = "${var.env_prefix}-igw"
    }
}

resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name: "${var.env_prefix}-main-rtb"
    }

}

resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id

    ingress { // for SSH
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"] #[var.my_ip]
    }

    ingress { // for NGINX server
        from_port = 8080
        to_port = 8080
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress { // all attributes configured to any/everything
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []

    }

    tags = {
        Name: "${var.env_prefix}-default-sg"
    }
}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent =  true
    owners = ["amazon"]
    filter {
        name = "name" // name of parameter to filter with
        values = [var.image_name]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_key_pair" "ssh-key" {
    key_name = "automated-server-key-pair-terraform"
    public_key = file(var.public_key_location) // use the existing id_rsa.pub on your laptop
}


resource "aws_instance" "myapp-server" {
    ami = "ami-05238ab1443fdf48f" #data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.availability_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    tags = {
        Name: "${var.env_prefix}-server"
    }
}

resource "null_resource" "configure_server" {

    triggers = {
        trigger = aws_instance.myapp-server.public_ip
    }
    provisioner "local-exec" {
      working_dir = "/Users/ausman/ansible"
      # run ansible playbook, and overwrite host file with the IP of this new server
      command = "ansible-playbook --inventory ${aws_instance.myapp-server.public_ip}, --private-key ${var.ssh_key_private} --user ec2-user deploy-docker-new-user.yaml"
    }
}

output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id
}

output "ec2_public_ip" {
    value = aws_instance.myapp-server.public_ip
}