
provider "aws" {}


variable "cidr_blocks" {
    description = "subnet cidr block"
    type = list(string)
}

variable "environment" {
    description= "deployment environment"
}

variable availability_zone{}

resource "aws_vpc" "development-vpc" { // aws_vpc is 'provider_resource' and development-vpc is the resource like a variable name
    cidr_block = var.cidr_blocks[0]
    tags = {
        Name: var.environment
    }
}

resource "aws_subnet" "dev-subnet-1" {
    vpc_id = aws_vpc.development-vpc.id // as the vpc above doesnt exist yet, so use resource.variable.id to get its id
    cidr_block = var.cidr_blocks[1]
    availability_zone = var.availability_zone// region has 3 AZs, so just chose one
    tags = {
        Name: "subnet-1-dev"
    }
}

