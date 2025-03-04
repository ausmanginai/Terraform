resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = var.vpc_id  // changed to a variable instead of referencing aws-vpc that is no longer in same file
    cidr_block = var.subnet_cidr_block
    availability_zone = var.availability_zone// region has 3 AZs, so just chose one
    tags = {
        Name: "${var.env_prefix}-subnet"
    }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = var.vpc_id
    tags = {
        Name = "${var.env_prefix}-igw"
    }
}

resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = var.default_route_table_id // changed to a variable

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id // does not need to be turned into a variable as this resource is in the same module
    }
    tags = {
        Name: "${var.env_prefix}-main-rtb"
    }

}