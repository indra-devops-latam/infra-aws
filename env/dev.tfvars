environment          = "dev"
aws_region           = "us-east-1"

cidr_block           = "10.10.0.0/16"
public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnet_cidrs = ["10.10.10.0/24", "10.10.20.0/24"]
azs                  = ["us-east-1a", "us-east-1b"]