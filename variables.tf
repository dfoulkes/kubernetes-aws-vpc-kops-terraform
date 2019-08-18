variable "name" {
  default = "myDomain.com"
}

variable "region" {
  default = "eu-west-1"
}

variable "azs" {
  default = ["eu-west-1a","eu-west-1b","eu-west-1c"]
  type    = "list"
}

variable "env" {
  default = "staging"
}

variable "vpc_cidr" {
  default = "10.20.0.0/16"
}
