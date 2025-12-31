variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

# From policy output
variable "tiers" {
  type = list(string)
}

variable "rules" {
  description = "SG-to-SG rules derived from policy"
  type = list(object({
    name      = string
    from_tier = string
    to_tier   = string
    protocol  = string
    from_port = number
    to_port   = number
    desc      = string
  }))
}

variable "allow_app_https_egress" {
  description = "Allow app tier to reach the internet on HTTPS (443) for patching."
  type        = bool
  default     = true
}
