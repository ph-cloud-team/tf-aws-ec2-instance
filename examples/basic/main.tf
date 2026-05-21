# Creates module-plan evidence for private SSM connectivity without reading real AWS in CI.
resource "aws_vpc_endpoint" "ssm_evidence" {
  # Creates one planned endpoint resource for each required SSM service.
  for_each = toset(["ssm", "ssmmessages", "ec2messages"])

  # Uses the example VPC ID variable.
  vpc_id = var.vpc_id

  # Builds the regional endpoint service name required by enterprise policy.
  service_name = "com.amazonaws.us-east-1.${each.value}"

  # Uses interface endpoints for Systems Manager services.
  vpc_endpoint_type = "Interface"

  # Uses the example private subnet ID.
  subnet_ids = [var.subnet_id]

  # Keeps the example endpoint private DNS behavior aligned with real foundation endpoints.
  private_dns_enabled = true

  # Applies example enterprise tags to the planned endpoint evidence.
  tags = {
    Name               = "dev-platform-${each.value}-endpoint"
    Environment        = "dev"
    Owner              = "platform-team"
    Application        = "platform-validation"
    CostCenter         = "shared-services"
    DataClassification = "internal"
  }
}

# Calls the local module source for CI certification and developer validation.
module "tf_aws_ec2_instance" {
  # Uses the module under test from the repository root.
  source = "../../"

  # Sets the enterprise workload name used for resource names and tags.
  name = "dev-platform-ec2"

  # Uses a placeholder AMI ID for static module plan validation.
  ami_id = "ami-0123456789abcdef0"

  # Uses a small default instance type for examples and test plans.
  instance_type = "t3.micro"

  # References an existing VPC ID supplied by the live environment.
  vpc_id = var.vpc_id

  # References an existing private subnet ID supplied by the live environment.
  subnet_id = var.subnet_id

  # Supplies the required enterprise IAM permissions boundary.
  permissions_boundary_arn = var.permissions_boundary_arn

  # Restricts outbound HTTPS to private enterprise network ranges by default.
  egress_cidr_blocks = ["10.0.0.0/8"]

  # Applies all mandatory enterprise tags required by plan policies.
  tags = {
    Name               = "dev-platform-ec2"
    Environment        = "dev"
    Owner              = "platform-team"
    Application        = "platform-validation"
    CostCenter         = "shared-services"
    DataClassification = "internal"
  }
}
