############################################
# Outputs for tf-aws-ec2-instance
############################################

output "module_name" {
  description = "Name of the Terraform module."
  value       = local.module_name
}

output "instance_id" {
  description = "EC2 instance ID used by AWS APIs, SSM, and AWX automation."
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IPv4 address used by AWX inventory and private operations."
  value       = aws_instance.this.private_ip
}

output "private_dns" {
  description = "Private DNS name assigned by AWS."
  value       = aws_instance.this.private_dns
}

output "iam_role_name" {
  description = "IAM role name attached to the EC2 instance profile."
  value       = aws_iam_role.this.name
}

output "iam_role_arn" {
  description = "IAM role ARN attached to the EC2 instance profile."
  value       = aws_iam_role.this.arn
}

output "instance_profile_name" {
  description = "IAM instance profile name attached to the EC2 instance."
  value       = aws_iam_instance_profile.this.name
}

output "security_group_id" {
  description = "Module-managed security group ID."
  value       = aws_security_group.this.id
}

output "status_check_alarm_name" {
  description = "CloudWatch status check alarm name created for the EC2 instance."
  value       = try(aws_cloudwatch_metric_alarm.status_check_failed[0].alarm_name, null)
}
