variables {
  environment          = "dev"
  aws_region           = "us-east-1"
}

# 1. Prueba de validación para los repositorios ECR de los microservicios
run "validate_ecr_repositories" {
  command = plan

  assert {
    condition     = contains(keys(module.ecr_repos), "client-gateway")
    error_message = "El repositorio ECR para 'client-gateway' no fue creado correctamente en el mapa."
  }
}

