variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

variable "tiers" { type = list(string) }

variable "rules" {
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
  type    = bool
  default = true
}
