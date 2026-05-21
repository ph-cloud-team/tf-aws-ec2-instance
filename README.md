# tf-aws-ec2-instance

Enterprise Terraform module for provisioning a private AWS EC2 instance that is managed through AWS Systems Manager instead of SSH.

## Purpose

This module owns the raw AWS resources required for one private EC2 workload instance:

- `aws_instance`
- `aws_security_group`
- `aws_vpc_security_group_egress_rule`
- `aws_iam_role`
- `aws_iam_instance_profile`
- required AWS-managed SSM role attachment
- optional AWS-managed CloudWatch agent role attachment

Live repos must call this module from the GitLab Terraform Module Registry. Live repos must not create raw EC2, IAM, or security group resources directly.

## Security Defaults

- No public IP address is assigned.
- No SSH ingress rule is created.
- IMDSv2 is required.
- Root EBS volume is encrypted.
- Additional EBS volumes are encrypted.
- IAM role requires an enterprise permissions boundary.
- SSM managed instance permissions are attached by default.
- Security group egress is limited to TCP/443 and caller-approved CIDRs.
- Required enterprise tags are applied to supported resources.

## GitLab Module Registry

After the module pipeline passes, publish by pushing a semantic version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The shared module pipeline publishes the module to:

```text
gitlab.midhtech.local/cloud_team/ec2-instance/aws
```

Live repos consume it like this:

```hcl
module "ec2_instance" {
  source  = "gitlab.midhtech.local/cloud_team/ec2-instance/aws"
  version = "1.0.0"

  name                     = "dev-platform-ec2"
  ami_id                   = var.ami_id
  vpc_id                   = data.aws_vpc.selected.id
  subnet_id                = data.aws_subnet.private.id
  permissions_boundary_arn = var.permissions_boundary_arn

  tags = {
    Name               = "dev-platform-ec2"
    Environment        = "dev"
    Owner              = "platform-team"
    Application        = "midh-dev-ec2"
    CostCenter         = "shared-services"
    DataClassification = "internal"
  }
}
```

## Required Inputs

| Name | Purpose |
| --- | --- |
| `name` | Enterprise workload name and default resource naming seed. |
| `ami_id` | Approved AMI ID from an image pipeline or controlled catalog. |
| `vpc_id` | Existing foundation-owned VPC ID. |
| `subnet_id` | Existing private subnet ID. |
| `permissions_boundary_arn` | IAM permissions boundary required by enterprise policy. |
| `tags` | Required enterprise tags. |

## Important Notes

This module does not create VPCs, subnets, route tables, NAT gateways, or VPC endpoints. Network foundation stacks own those resources.

Live EC2 repos must reference existing SSM VPC endpoints with data sources for:

- `ssm`
- `ssmmessages`
- `ec2messages`

That gives OPA plan policy evidence that the instance can be managed privately without forcing every workload repo to recreate foundation networking.

## Validation

The module pipeline runs:

- Terraform format
- Terraform validate
- module source OPA checks
- Checkov
- TFLint
- module example plan
- enterprise plan OPA checks
- module registry publish on semantic version tags

Local quick checks:

```bash
terraform fmt -check -recursive
cd examples/basic
terraform init
terraform validate
```
