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
