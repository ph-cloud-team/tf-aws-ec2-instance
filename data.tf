############################################
# Data sources for tf-aws-ec2-instance
############################################

# Reads the current AWS partition so ARNs work in commercial, GovCloud, or China partitions.
data "aws_partition" "current" {}

# Builds the EC2 trust policy used by the instance role.
data "aws_iam_policy_document" "ec2_assume_role" {
  # Allows only the EC2 service to assume this role.
  statement {
    # Names the trust statement for audit readability.
    sid = "AllowEC2ServiceAssumeRole"

    # Allows the trust relationship.
    effect = "Allow"

    # Defines the trusted AWS service principal.
    principals {
      # Identifies this principal as an AWS service.
      type = "Service"

      # Allows EC2 instances to assume the role.
      identifiers = ["ec2.${data.aws_partition.current.dns_suffix}"]
    }

    # Grants the STS operation required for instance profile role assumption.
    actions = ["sts:AssumeRole"]
  }
}
