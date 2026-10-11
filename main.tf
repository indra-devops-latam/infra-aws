module "ecr_repos" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.0"

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