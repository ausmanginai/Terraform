module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  cluster_name = "myapp-eks-cluster" // as referenced in vpc.tf in subnet tags
  cluster_version = "1.27" // kubernetes version
  cluster_endpoint_public_access = true

  subnet_ids = module.myapp-vpc.private_subnets // module registry shows private_subnets is 
  // an output and provides subnet ids of private subnets
  vpc_id = module.myapp-vpc.vpc_id

  tags = {
    environment = "dev"
    application = "myapp"
  }

  eks_managed_node_groups = {
    dev = {
      instance_types = ["t2.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }
  enable_cluster_creator_admin_permissions = true // Note: If you are using EKS module
  // version v20.1.0+ you will need to add the following line to your EKS Terraform file
}