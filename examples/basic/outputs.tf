output "instance_id" {
  description = "EC2 instance ID from the module example."
  value       = module.tf_aws_ec2_instance.instance_id
}

output "private_ip" {
  description = "Private IP from the module example."
  value       = module.tf_aws_ec2_instance.private_ip
}

output "security_group_id" {
  description = "Security group ID from the module example."
  value       = module.tf_aws_ec2_instance.security_group_id
}

output "ssm_endpoint_evidence" {
  description = "Example-only SSM endpoint evidence references used by enterprise plan policy."
  value = {
    for service, endpoint in aws_vpc_endpoint.ssm_evidence : service => endpoint.service_name
  }
}
