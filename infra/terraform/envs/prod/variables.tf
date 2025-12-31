variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "cloud-network-segmentation"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "tags" {
  type = map(string)
  default = {
    Owner = "eunis"
  }
}

variable "az_count" {
  type    = number
  default = 2
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

# Provide 2 CIDRs per tier (one per AZ) when az_count=2
variable "dmz_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.0.0/20", "10.20.16.0/20"]
}

variable "app_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.32.0/20", "10.20.48.0/20"]
}

variable "data_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.64.0/20", "10.20.80.0/20"]
}

variable "endpoints_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.96.0/20", "10.20.112.0/20"]
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "flow_logs_retention_in_days" {
  type    = number
  default = 30
}

variable "policy_tiers" {
  type    = list(string)
  default = ["dmz", "app", "data", "endpoints"]
}

variable "policy_rules" {
  type = list(object({
    name      = string
    from_tier = string
    to_tier   = string
    protocol  = string
    from_port = number
    to_port   = number
    desc      = string
  }))
  default = []
}

variable "allow_app_https_egress" {
  type    = bool
  default = true
}
