resource "aws_default_security_group" "default-sg" {
    vpc_id = var.vpc_id

    ingress { // for SSH
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = [var.my_ip]
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
        values = ["amzn2-ami-kernel-*-x86_64-gp2"]
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
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type // new variable

    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.availability_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    user_data = file("./modules/webserver/entry-script.sh")
    
    user_data_replace_on_change = true // this will ensure the user-data is re-executed when user-data itself is modified

    tags = {
        Name: "${var.env_prefix}-server"
    }
}
