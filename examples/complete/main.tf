# Calls the local module source with optional enterprise features enabled.
module "tf_aws_ec2_instance" {
  # Uses the module under test from the repository root.
  source = "../../"

  # Sets the workload name used for naming and the Name tag.
  name = "dev-platform-ec2-complete"

  # Supplies an approved AMI ID from the live environment or image catalog.
  ami_id = var.ami_id

  # Uses the caller-selected instance type.
  instance_type = var.instance_type

  # Places the instance in an existing foundation-owned VPC.
  vpc_id = var.vpc_id

  # Places the instance in an existing private subnet.
  subnet_id = var.subnet_id

  # Enforces the enterprise permissions boundary on the IAM role.
  permissions_boundary_arn = var.permissions_boundary_arn

  # Uses a customer-managed KMS key for EBS encryption when supplied.
  kms_key_id = var.kms_key_id

  # Sets an enterprise baseline root volume size.
  root_volume_size = 40

  # Adds one encrypted data volume for workloads that need separate storage.
  additional_ebs_volumes = [
    {
      device_name           = "/dev/sdf"
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
    }
  ]

  # Allows only HTTPS egress to approved private network ranges.
  egress_cidr_blocks = var.egress_cidr_blocks

  # Allows AWX or user data to configure the CloudWatch agent after provisioning.
  attach_cloudwatch_agent_policy = true

  # Applies all mandatory enterprise tags required by plan policies.
  tags = {
    Name               = "dev-platform-ec2-complete"
    Environment        = "dev"
    Owner              = "platform-team"
    Application        = "platform-validation"
    CostCenter         = "shared-services"
    DataClassification = "internal"
  }
}
