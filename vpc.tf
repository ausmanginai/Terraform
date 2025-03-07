provider "aws" {
    region = "eu-west-1"
}

variable private_subnet_cidr_blocks {}
variable public_subnet_cidr_blocks {}
variable vpc_cidr_block {}

data "aws_availability_zones" "azs" {}

module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws" // existing module
  version = "5.19.0"
  
  // all these input attributes can be looked up on the module registry [they arent just assigned random names]
  
  name = "myapp-vpc"
  cidr = var.vpc_cidr_block
  private_subnets = var.private_subnet_cidr_blocks
  public_subnets = var.public_subnet_cidr_blocks
  azs = data.aws_availability_zones.azs.names // reference data source

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"  // to help ccm [cloud-controller-manager] identify 
     // which vpc and subnets it should connect to
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/elb" = 1 // k8s needs to know which one is the public subnet so 
    // that it can create/provision the load balancer there

  }

  private_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}