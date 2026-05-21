############################################
# Local values for tf-aws-ec2-instance
############################################

locals {
  # Keeps the module name in one place for tags and documentation-oriented outputs.
  module_name = "tf-aws-ec2-instance"

  # Standardizes enterprise tags on every taggable resource created by this module.
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Module    = local.module_name
    }
  )

  # Uses a deterministic IAM role name unless a caller supplies an override.
  iam_role_name = coalesce(var.iam_role_name, "${var.name}-role")

  # Uses a deterministic instance profile name unless a caller supplies an override.
  instance_profile_name = coalesce(var.instance_profile_name, "${var.name}-profile")

  # Uses a deterministic security group name unless a caller supplies an override.
  security_group_name = coalesce(var.security_group_name, "${var.name}-sg")

  # Uses caller-supplied user data when present, otherwise leaves user data unset.
  user_data = var.enable_ssm_agent_bootstrap ? trimspace("${var.user_data}\n${var.ssm_agent_bootstrap_script}") : var.user_data
}
