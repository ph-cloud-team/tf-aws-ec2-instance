output "instance_id" {
  description = "EC2 instance ID from the complete module example."
  value       = module.tf_aws_ec2_instance.instance_id
}

output "private_ip" {
  description = "Private IP from the complete module example."
  value       = module.tf_aws_ec2_instance.private_ip
}

output "iam_role_name" {
  description = "IAM role name from the complete module example."
  value       = module.tf_aws_ec2_instance.iam_role_name
}

output "security_group_id" {
  description = "Security group ID from the complete module example."
  value       = module.tf_aws_ec2_instance.security_group_id
}
