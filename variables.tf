############################################
# Input variables for tf-aws-ec2-instance
############################################

variable "name" {
  description = "Enterprise-compliant workload name used for resource names and the required Name tag. Use lowercase letters, numbers, and hyphens only."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,62}$", var.name))
    error_message = "name must be 3-63 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "ami_id" {
  description = "Approved AMI ID supplied by the live repo from an enterprise image pipeline, golden AMI catalog, or controlled variable."
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-f]{8,17}$", var.ami_id))
    error_message = "ami_id must look like an AWS AMI ID, for example ami-0123456789abcdef0."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the private instance."
  type        = string
  default     = "t3.micro"
}

variable "monitoring_enabled" {
  description = "Enables detailed CloudWatch monitoring on the EC2 instance."
  type        = bool
  default     = true
}

variable "ebs_optimized" {
  description = "Enables EBS optimization for supported EC2 instance types."
  type        = bool
  default     = true
}

variable "imds_http_tokens" {
  description = "IMDS token enforcement mode. Enterprise default is required and must stay required for IMDSv2 compliance."
  type        = string
  default     = "required"

  validation {
    condition     = var.imds_http_tokens == "required"
    error_message = "imds_http_tokens must be required to enforce IMDSv2."
  }
}

variable "vpc_id" {
  description = "Existing VPC ID owned by the network foundation stack."
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8,17}$", var.vpc_id))
    error_message = "vpc_id must look like an AWS VPC ID."
  }
}

variable "subnet_id" {
  description = "Existing private subnet ID owned by the network foundation stack. This module never assigns a public IP."
  type        = string

  validation {
    condition     = can(regex("^subnet-[0-9a-f]{8,17}$", var.subnet_id))
    error_message = "subnet_id must look like an AWS subnet ID."
  }
}

variable "permissions_boundary_arn" {
  description = "Enterprise IAM permissions boundary ARN required for the EC2 instance role."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:iam::[0-9]{12}:policy/.+", var.permissions_boundary_arn))
    error_message = "permissions_boundary_arn must be an IAM policy ARN in the target AWS account."
  }
}

variable "kms_key_id" {
  description = "Optional KMS key ID or ARN used to encrypt root and additional EBS volumes. When null, the AWS account EBS default KMS key is used."
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Encrypted root EBS volume size in GiB."
  type        = number
  default     = 30

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "root_volume_size must be at least 8 GiB."
  }
}

variable "root_volume_type" {
  description = "Encrypted root EBS volume type."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2"], var.root_volume_type)
    error_message = "root_volume_type must be one of gp3, gp2, io1, or io2."
  }
}

variable "additional_ebs_volumes" {
  description = "Optional encrypted additional EBS volumes attached at instance launch."
  type = list(object({
    device_name           = string
    volume_size           = number
    volume_type           = string
    delete_on_termination = bool
  }))
  default = []
}

variable "additional_security_group_ids" {
  description = "Optional additional approved security group IDs to attach to the instance."
  type        = list(string)
  default     = []
}

variable "egress_cidr_blocks" {
  description = "Approved IPv4 CIDR blocks allowed for outbound TCP/443. Use private VPC or endpoint CIDRs where possible."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "key_name" {
  description = "Optional EC2 key pair name. Enterprise default is null because access should use AWS Systems Manager Session Manager."
  type        = string
  default     = null
}

variable "user_data" {
  description = "Optional user data script for approved bootstrap actions."
  type        = string
  default     = ""
}

variable "enable_ssm_agent_bootstrap" {
  description = "When true, appends a small SSM agent bootstrap script to user_data. Most enterprise AMIs should already include SSM Agent."
  type        = bool
  default     = false
}

variable "ssm_agent_bootstrap_script" {
  description = "Optional bootstrap script appended when enable_ssm_agent_bootstrap is true."
  type        = string
  default     = <<-EOT
    #!/bin/bash
    set -e
    systemctl enable amazon-ssm-agent || true
    systemctl start amazon-ssm-agent || true
  EOT
}

variable "attach_cloudwatch_agent_policy" {
  description = "When true, attaches CloudWatchAgentServerPolicy so AWX or user_data can configure the CloudWatch agent after provisioning."
  type        = bool
  default     = false
}

variable "create_status_check_alarm" {
  description = "Creates a baseline EC2 StatusCheckFailed CloudWatch alarm required by enterprise monitoring policy."
  type        = bool
  default     = true
}

variable "status_check_alarm_period" {
  description = "CloudWatch alarm period in seconds for the EC2 status check alarm."
  type        = number
  default     = 60
}

variable "status_check_alarm_evaluation_periods" {
  description = "Number of periods evaluated by the EC2 status check alarm."
  type        = number
  default     = 2
}

variable "alarm_actions" {
  description = "Optional SNS topic ARNs or automation action ARNs called when the EC2 status check alarm enters ALARM state."
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "Optional SNS topic ARNs or automation action ARNs called when the EC2 status check alarm returns to OK state."
  type        = list(string)
  default     = []
}

variable "insufficient_data_actions" {
  description = "Optional SNS topic ARNs or automation action ARNs called when the EC2 status check alarm has insufficient data."
  type        = list(string)
  default     = []
}

variable "iam_role_name" {
  description = "Optional override for the IAM role name. Defaults to <name>-role."
  type        = string
  default     = null
}

variable "instance_profile_name" {
  description = "Optional override for the IAM instance profile name. Defaults to <name>-profile."
  type        = string
  default     = null
}

variable "security_group_name" {
  description = "Optional override for the security group name. Defaults to <name>-sg."
  type        = string
  default     = null
}

variable "tags" {
  description = "Enterprise tags applied to all supported resources. Must include Name, Environment, Owner, Application, CostCenter, and DataClassification."
  type        = map(string)

  validation {
    condition = alltrue([
      for required_tag in ["Name", "Environment", "Owner", "Application", "CostCenter", "DataClassification"] :
      contains(keys(var.tags), required_tag)
    ])
    error_message = "tags must include Name, Environment, Owner, Application, CostCenter, and DataClassification."
  }
}
