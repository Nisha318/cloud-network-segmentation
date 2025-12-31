variable "name_prefix" { type = string }
variable "vpc_id"      { type = string }

variable "retention_in_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
