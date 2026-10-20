variable "services" {
  type = list(string)
  default = [
    "client-gateway"
  ]
}
/*
"auth-ms",
    "orders-ms",
    "products-ms",
    "payments-ms",
    "nats-broker"
*/
variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "azs" {
  type = list(string)
}

variable "cluster_name" {
  type = string
}

variable "instance_types" {
  type = list(string)
}

variable "desired_size" {
  type = number
}

variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "kms_key_administrators" {
  description = "ARNs de los roles o usuarios que administran la clave KMS"
  type        = list(string)
}