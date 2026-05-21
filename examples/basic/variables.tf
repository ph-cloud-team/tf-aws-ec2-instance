variable "vpc_id" {
  description = "Existing VPC ID used by the module example plan."
  type        = string
  default     = "vpc-0123456789abcdef0"
}

variable "subnet_id" {
  description = "Existing private subnet ID used by the module example plan."
  type        = string
  default     = "subnet-0123456789abcdef0"
}

variable "permissions_boundary_arn" {
  description = "Enterprise IAM permissions boundary ARN used by the module example plan."
  type        = string
}
