environment          = "prod"
aws_region           = "us-east-1"

cidr_block           = "10.20.0.0/16"
public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
private_subnet_cidrs = ["10.20.10.0/24", "10.20.20.0/24"]
azs                  = ["us-east-1a", "us-east-1b"]