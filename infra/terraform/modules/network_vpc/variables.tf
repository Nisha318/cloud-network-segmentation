variable "name_prefix" { type = string }
variable "aws_region"  { type = string }

variable "vpc_cidr" { type = string }
variable "az_count" { type = number }

variable "dmz_subnet_cidrs"       { type = list(string) }
variable "app_subnet_cidrs"       { type = list(string) }
variable "data_subnet_cidrs"      { type = list(string) }
variable "endpoints_subnet_cidrs" { type = list(string) }

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
