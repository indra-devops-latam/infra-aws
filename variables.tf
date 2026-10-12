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