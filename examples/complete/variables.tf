variable "ami_id" {
  description = "Approved AMI ID used by the complete module example."
  type        = string
  default     = "ami-0123456789abcdef0"
}

variable "instance_type" {
  description = "EC2 instance type used by the complete module example."
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "Existing VPC ID used by the complete module example."
  type        = string
  default     = "vpc-0123456789abcdef0"
}

variable "subnet_id" {
  description = "Existing private subnet ID used by the complete module example."
  type        = string
  default     = "subnet-0123456789abcdef0"
}

variable "permissions_boundary_arn" {
  description = "Enterprise IAM permissions boundary ARN used by the complete module example."
  type        = string
}

variable "kms_key_id" {
  description = "Optional KMS key ID or ARN for EBS encryption in the complete example."
  type        = string
  default     = null
}

variable "egress_cidr_blocks" {
  description = "Approved private CIDR blocks for outbound HTTPS in the complete example."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}
