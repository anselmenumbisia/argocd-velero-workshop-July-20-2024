module "eks_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access = true
  iam_role_name                  = "${var.cluster_name}-cluster-role"
  iam_role_use_name_prefix       = false

  enable_irsa                     = true
  create_kms_key                  = true
  kms_key_deletion_window_in_days = 7
  kms_key_aliases                 = ["cluster-key"]

  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  vpc_id = module.vpc.vpc_id

  subnet_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    managed = {
      use_custom_launch_template = false
      public_subnets             = module.vpc.public_subnets
      subnet_ids                 = module.vpc.private_subnets
      min_size                   = 2
      max_size                   = 5
      desired_size               = 2
      instance_types             = ["t2.large"]
      capacity_type              = "ON_DEMAND"
      iam_role_name              = "${var.cluster_name}-node-role"
      iam_role_use_name_prefix   = false
      iam_role_path              = "/"
      key_name                   = "eks-cluster-key"
      tags = {
        Name = "managed"
      }
      ebs = {
        volume_size           = 30
        volume_type           = "gp3"
        delete_on_termination = true
      }
      enclave_enabled   = false
      enable_monitoring = true
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
      }


    }
  }

  cluster_enabled_log_types   = ["audit", "api", "authenticator", "controllerManager", "scheduler"]
  create_cloudwatch_log_group = true

  # # Fargate Profile(s)
  # fargate_profiles = {
  #   default = {
  #     name       = "default"
  #     subnet_ids = module.vpc.private_subnets
  #     selectors = [
  #       {
  #         namespace = "default"
  #       }
  #     ]
  #   }
  #   innov = {
  #     name       = "innov"
  #     subnet_ids = module.vpc.private_subnets
  #     selectors = [
  #       {
  #         namespace = "innov-namespace"
  #       }
  #     ]
  #   }
  # }

  enable_cluster_creator_admin_permissions = true

  # access_entries = {
  #   cluster-admin1 = {

  #     kubernetes_groups = ["admins"]
  #     principal_arn     = "arn:aws:iam::389029577690:user/developer" #module.development_team.iam_role_arn
  #     policy_associations = {
  #       cluster-admin = {
  #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  #           access_scope = {  
  #             #namespaces = ["cluster"]
  #             type       = "cluster"

  #           }
  #       }
  #     }

  #   },

  #   cluster-admin2 = {

  #     kubernetes_groups = ["admin"]
  #     principal_arn     = "arn:aws:iam::389029577690:user/manager" #module.development_team.iam_role_arn
  #     policy_associations = {
  #       cluster-admin = {
  #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  #           access_scope = {  
  #             #namespaces = ["cluster"]
  #             type       = "cluster"

  #           }
  #       }
  #     }

  #   },


  #   cluster-admin3 = {

  #     kubernetes_groups = ["admin"]
  #     principal_arn     = "arn:aws:iam::389029577690:user/kingsley" #module.development_team.iam_role_arn
  #     policy_associations = {
  #       cluster-admin = {
  #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  #           access_scope = {  
  #             namespaces = ["default", "innov-namespace"]
  #             type       = "namespace"

  #           }
  #       }
  #     }

  #   },

  # }


  # manage_aws_auth_configmap = true

  # aws_auth_roles = [
  #   {
  #     rolearn  = "arn:aws:iam::389029577690:role/team-platform-20231208173344295400000020"
  #     username = "cluster-admin"
  #     groups   = ["system:masters"]
  #   },
  # ]

  tags = {
    Environment = "sandbox"
    Terraform   = "true"
  }
}



# Module for EKS blueprint addons

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = ">= 1.12.0" #ensure to update this to the latest/desired version

  cluster_name      = module.eks_cluster.cluster_name
  cluster_endpoint  = module.eks_cluster.cluster_endpoint
  cluster_version   = module.eks_cluster.cluster_version
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn

  #   eks_addons = {
  #     aws-ebs-csi-driver = {
  #       most_recent = true
  #     }
  #     coredns = {
  #       most_recent = true
  #     }
  #     vpc-cni = {
  #       most_recent = true
  #     }
  #     kube-proxy = {
  #       most_recent = true
  #     }
  #   }

  # ingress
  enable_aws_load_balancer_controller = true
  enable_external_dns                 = true
  enable_ingress_nginx                = false

  # cluster autosclaing
  # enable_cluster_autoscaler = true
  enable_karpenter = true

  # cluster backup
  #enable_velero = true

  # volumes
  enable_aws_efs_csi_driver = true


  #observability
  enable_aws_for_fluentbit      = true
  enable_aws_cloudwatch_metrics = true
  enable_metrics_server         = true
  enable_fargate_fluentbit      = true

  tags = {
    Environment = "sandbox"
    Terraform   = "true"
  }
}