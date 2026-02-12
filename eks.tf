module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = "demo-eks"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      desired_size   = 3
      min_size       = 3
      max_size       = 4
      instance_types = ["t3.medium"]
    }
  }

  access_entries = {
    github = {
      principal_arn = "arn:aws:iam::596560793647:role/github-actions-role"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    local_user = {
      principal_arn = "arn:aws:iam::596560793647:user/terraform-github-user"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}
