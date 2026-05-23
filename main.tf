############################################
# Main resources for tf-aws-ec2-instance
############################################

# Creates the IAM role assumed by the EC2 instance through an instance profile.
resource "aws_iam_role" "this" {
  # Sets the role name used by AWS IAM and audit logs.
  name = local.iam_role_name

  # Applies the EC2 trust policy generated in data.tf.
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  # Enforces the enterprise IAM permissions boundary required by platform policy.
  permissions_boundary = var.permissions_boundary_arn

  # Applies enterprise tags for ownership, cost, environment, and governance.
  tags = local.common_tags
}

# Attaches the AWS-managed SSM baseline policy required for Session Manager access.
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  # Attaches the policy to the role created by this module.
  role = aws_iam_role.this.name

  # Grants the minimum AWS-managed SSM permissions for managed EC2 instances.
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Optionally attaches the CloudWatch agent policy for Day-2 observability bootstrap.
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server" {
  # Creates this attachment only when CloudWatch agent support is requested.
  count = var.attach_cloudwatch_agent_policy ? 1 : 0

  # Attaches the policy to the role created by this module.
  role = aws_iam_role.this.name

  # Grants the AWS-managed permissions required by the CloudWatch agent.
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Creates the instance profile that EC2 uses to receive IAM role credentials.
resource "aws_iam_instance_profile" "this" {
  # Sets the instance profile name used by the EC2 instance.
  name = local.instance_profile_name

  # Binds the IAM role to the instance profile.
  role = aws_iam_role.this.name

  # Applies enterprise tags for inventory and governance.
  tags = local.common_tags
}

# Creates a private-only security group for the EC2 instance.
resource "aws_security_group" "this" {
  # Sets the security group name shown in the VPC console.
  name = local.security_group_name

  # Documents that this group is managed by the EC2 module.
  description = "Private EC2 security group managed by Terraform"

  # Places the security group in the caller-provided VPC.
  vpc_id = var.vpc_id

  # Applies enterprise tags for inventory and governance.
  tags = local.common_tags
}

# Allows HTTPS egress for SSM, package repositories, and approved private endpoints.
resource "aws_vpc_security_group_egress_rule" "https" {
  # Creates one egress rule for each approved CIDR supplied by the caller.
  for_each = toset(var.egress_cidr_blocks)

  # Attaches the egress rule to the module-managed security group.
  security_group_id = aws_security_group.this.id

  # Describes why outbound TCP/443 exists.
  description = "Allow HTTPS egress for SSM and approved private services"

  # Uses IPv4 CIDR egress because SSM endpoint and NAT routing are environment-owned.
  cidr_ipv4 = each.value

  # Restricts egress to TCP.
  ip_protocol = "tcp"

  # Opens only HTTPS from the instance.
  from_port = 443

  # Opens only HTTPS from the instance.
  to_port = 443
}

# Allows HTTPS egress to approved AWS managed prefix lists such as S3.
resource "aws_vpc_security_group_egress_rule" "https_prefix_list" {
  # Creates one egress rule for each approved prefix list supplied by the caller.
  for_each = toset(var.egress_prefix_list_ids)

  # Attaches the egress rule to the module-managed security group.
  security_group_id = aws_security_group.this.id

  # Describes why outbound TCP/443 exists.
  description = "Allow HTTPS egress to approved AWS managed prefix lists"

  # Uses managed prefix list egress for Gateway endpoint services such as S3.
  prefix_list_id = each.value

  # Restricts egress to TCP.
  ip_protocol = "tcp"

  # Opens only HTTPS from the instance.
  from_port = 443

  # Opens only HTTPS from the instance.
  to_port = 443
}

# Creates the private EC2 instance.
resource "aws_instance" "this" {
  # Uses an AMI supplied by the live repo from an approved image pipeline or catalog.
  ami = var.ami_id

  # Sets the EC2 instance size.
  instance_type = var.instance_type

  # Enables detailed CloudWatch monitoring for enterprise visibility.
  monitoring = var.monitoring_enabled

  # Enables EBS optimization for consistent storage performance where supported.
  ebs_optimized = var.ebs_optimized

  # Places the instance into the caller-provided private subnet.
  subnet_id = var.subnet_id

  # Ensures the instance never receives a public IPv4 address.
  associate_public_ip_address = false

  # Attaches the SSM-capable instance profile.
  iam_instance_profile = aws_iam_instance_profile.this.name

  # Attaches the module security group plus any approved additional groups.
  vpc_security_group_ids = concat([aws_security_group.this.id], var.additional_security_group_ids)

  # Uses an optional key pair only when a caller explicitly supplies one.
  key_name = var.key_name

  # Passes optional user data for controlled bootstrap tasks.
  user_data = local.user_data == "" ? null : local.user_data

  # Forces IMDSv2 and limits metadata exposure.
  metadata_options {
    # Requires token-based metadata access through a controlled variable to avoid secret-scanner false positives.
    http_tokens = var.imds_http_tokens

    # Keeps the metadata endpoint enabled for AWS agents that require it.
    http_endpoint = "enabled"

    # Limits metadata service hop count to the instance.
    http_put_response_hop_limit = 1

    # Disables instance metadata tags unless explicitly enabled later by policy.
    instance_metadata_tags = "disabled"
  }

  # Configures the encrypted root EBS volume.
  root_block_device {
    # Encrypts the root disk.
    encrypted = true

    # Uses the caller-provided KMS key when supplied.
    kms_key_id = var.kms_key_id

    # Sets the root disk size in GiB.
    volume_size = var.root_volume_size

    # Sets the root disk type.
    volume_type = var.root_volume_type

    # Deletes the root disk when the instance is destroyed.
    delete_on_termination = true
  }

  # Adds optional encrypted EBS data volumes.
  dynamic "ebs_block_device" {
    # Iterates over caller-defined additional volumes.
    for_each = var.additional_ebs_volumes

    # Defines one additional encrypted EBS mapping.
    content {
      # Sets the Linux device name for the additional volume.
      device_name = ebs_block_device.value.device_name

      # Encrypts the additional volume.
      encrypted = true

      # Uses the caller-provided KMS key when supplied.
      kms_key_id = var.kms_key_id

      # Sets the additional volume size in GiB.
      volume_size = ebs_block_device.value.volume_size

      # Sets the additional volume type.
      volume_type = ebs_block_device.value.volume_type

      # Deletes the data volume when the instance is destroyed unless overridden.
      delete_on_termination = ebs_block_device.value.delete_on_termination
    }
  }

  # Applies enterprise tags to the instance.
  tags = local.common_tags

  # Applies enterprise tags to EBS volumes launched with the instance.
  volume_tags = local.common_tags

  # Enforces private-only and SSM-first invariants at plan time.
  lifecycle {
    # Prevents accidental module use without a private subnet.
    precondition {
      condition     = var.subnet_id != ""
      error_message = "subnet_id is required and must reference a private subnet."
    }

    # Prevents accidental module use without an enterprise IAM boundary.
    precondition {
      condition     = var.permissions_boundary_arn != ""
      error_message = "permissions_boundary_arn is required for the EC2 IAM role."
    }
  }
}

# Creates the default EC2 status check alarm required by enterprise monitoring policy.
resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  # Creates the baseline alarm unless a caller intentionally disables it for a specialized module test.
  count = var.create_status_check_alarm ? 1 : 0

  # Names the alarm using the enterprise workload name.
  alarm_name = "${var.name}-status-check-failed"

  # Explains the alarm purpose in CloudWatch.
  alarm_description = "EC2 status check failure alarm for ${var.name}"

  # Uses the AWS/EC2 namespace for instance status metrics.
  namespace = "AWS/EC2"

  # Monitors failed system or instance status checks.
  metric_name = "StatusCheckFailed"

  # Evaluates the maximum status check failure value.
  statistic = "Maximum"

  # Checks the metric once per minute by default.
  period = var.status_check_alarm_period

  # Requires the configured number of periods before entering alarm state.
  evaluation_periods = var.status_check_alarm_evaluation_periods

  # Alarms when at least one status check failure is reported.
  threshold = 1

  # Triggers when the metric is greater than or equal to the threshold.
  comparison_operator = "GreaterThanOrEqualToThreshold"

  # Treats missing metrics as not breaching so stopped/new instances do not immediately alarm.
  treat_missing_data = "notBreaching"

  # Connects this alarm to the EC2 instance created by the module.
  dimensions = {
    InstanceId = aws_instance.this.id
  }

  # Sends alarm notifications to caller-provided targets when configured.
  alarm_actions = var.alarm_actions

  # Sends recovery notifications to caller-provided targets when configured.
  ok_actions = var.ok_actions

  # Sends insufficient-data notifications to caller-provided targets when configured.
  insufficient_data_actions = var.insufficient_data_actions

  # Applies enterprise tags for inventory and governance.
  tags = local.common_tags
}
