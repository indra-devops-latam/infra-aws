module "ecr_repos" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 3.2.0"

  for_each = toset(var.services)

  repository_name = "ecr-${each.key}-${var.environment}"

  # Parámetros correctos del módulo oficial de ECR
  repository_image_tag_mutability = "MUTABLE"
  repository_image_scan_on_push   = true
  create_lifecycle_policy         = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.7.3"

  name = "vpc-${var.environment}"
  cidr = var.cidr_block

  azs             = var.azs
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway   = true
  single_nat_gateway   = true # Ponlo en false si en prod quieres un NAT Gateway por cada Zona de Disponibilidad
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Subnets públicas: ALB internet-facing
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  # Subnets privadas: recursos internos
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.29.0"

  name               = var.cluster_name
  kubernetes_version = "1.37" # O la versión que prefieras de Kubernetes

  endpoint_public_access = true
  # Solo acceso privado al API Server
  # endpoint_public_access_cidrs=[
  #   "38.25.4.119/32",
  #   "163.116.229.143/32"
  # ]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # ✅ AGREGAR ESTO — Addons esenciales de EKS
  addons = {
    vpc-cni = {
      most_recent                 = true
      before_compute              = true # Se instala ANTES de los nodos
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    kube-proxy = {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
    }
    coredns = {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  # Configuración de los Node Groups administrados
  eks_managed_node_groups = {
    default = {
      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      instance_types = var.instance_types
      capacity_type  = "ON_DEMAND"
    }
  }

  kms_key_administrators = var.kms_key_administrators

  enable_irsa = true

  authentication_mode = "API_AND_CONFIG_MAP"

  access_entries = {
    github_actions = {
      principal_arn = var.kms_key_administrators[0]

      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    local_terraform = {
      principal_arn = var.kms_key_administrators[1]

      policy_associations = {
        cluster_admin_view = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
        admin_view = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}


module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"

  name            = "${var.cluster_name}-aws-load-balancer-controller"
  use_name_prefix = false

  attach_load_balancer_controller_policy = true
  permissions                            = {}

  oidc_providers = {
    main = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "kube-system:aws-load-balancer-controller"
      ]
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.6.0"
  namespace  = "kube-system"

  values = [
    yamlencode({
      clusterName = var.cluster_name
      region      = var.aws_region
      vpcId       = module.vpc.vpc_id

      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"

        annotations = {
          "eks.amazonaws.com/role-arn" = module.aws_load_balancer_controller_irsa.arn
        }
      }
    })
  ]

  depends_on = [
    module.eks,
    module.aws_load_balancer_controller_irsa
  ]
}