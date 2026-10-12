variables {
  environment          = "dev"
  aws_region           = "us-east-1"
  cidr_block           = "10.0.0.0/16"
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.3.0/24", "10.0.4.0/24"]
  azs                  = ["us-east-1a", "us-east-1b"]
}

# 1. Prueba de validación para los repositorios ECR de los microservicios
run "validate_ecr_repositories" {
  command = plan

  assert {
    condition     = contains(keys(module.ecr_repos), "client-gateway")
    error_message = "El repositorio ECR para 'client-gateway' no fue creado correctamente en el mapa."
  }
}

# 2. Prueba de validación de variables de entorno y VPC
run "validate_vpc_configuration" {
  command = plan

  # Validamos el CIDR de la VPC en lugar del ID (que requiere apply)
  assert {
    condition     = module.vpc.vpc_cidr_block == "10.0.0.0/16"
    error_message = "El bloque CIDR de la VPC no coincide con el esperado."
  }

  assert {
    condition     = length(module.vpc.private_subnets) == 2
    error_message = "Debe haber exactamente 2 subredes privadas configuradas."
  }
}