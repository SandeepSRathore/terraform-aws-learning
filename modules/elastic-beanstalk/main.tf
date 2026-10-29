# Elastic Beanstalk = "give me your code, I'll run it". Behind the scenes it
# creates EC2 instances, security groups and (optionally) a load balancer.
# With no application version uploaded, it deploys a sample app.

data "aws_elastic_beanstalk_solution_stack" "this" {
  most_recent = true
  name_regex  = var.solution_stack_regex
}

# ---- IAM: two roles Beanstalk needs ----

# 1. Instance role: what the EC2 instances themselves may do.
resource "aws_iam_role" "instance" {
  name = "${var.name}-eb-instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "instance" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

# EC2 can't use a role directly; it needs an "instance profile" wrapper.
resource "aws_iam_instance_profile" "instance" {
  name = "${var.name}-eb-instance"
  role = aws_iam_role.instance.name
}

# 2. Service role: what Beanstalk itself may do (health checks, updates).
resource "aws_iam_role" "service" {
  name = "${var.name}-eb-service"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "elasticbeanstalk.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "service" {
  for_each = toset([
    "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth",
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy",
  ])

  role       = aws_iam_role.service.name
  policy_arn = each.value
}

# ---- The application and its running environment ----

resource "aws_elastic_beanstalk_application" "this" {
  name = var.name

  tags = var.tags
}

locals {
  # Beanstalk is configured through namespace/name/value "option settings".
  base_settings = [
    { namespace = "aws:elasticbeanstalk:environment", name = "EnvironmentType", value = var.environment_type },
    { namespace = "aws:elasticbeanstalk:environment", name = "ServiceRole", value = aws_iam_role.service.name },
    { namespace = "aws:autoscaling:launchconfiguration", name = "IamInstanceProfile", value = aws_iam_instance_profile.instance.name },
    # New AWS accounts can't use launch configurations; disabling IMDSv1
    # makes Beanstalk use launch templates instead.
    { namespace = "aws:autoscaling:launchconfiguration", name = "DisableIMDSv1", value = "true" },
    { namespace = "aws:ec2:instances", name = "InstanceTypes", value = var.instance_type },
    { namespace = "aws:ec2:vpc", name = "VPCId", value = var.vpc_id },
    { namespace = "aws:ec2:vpc", name = "Subnets", value = join(",", var.subnet_ids) },
    { namespace = "aws:ec2:vpc", name = "AssociatePublicIpAddress", value = "true" },
    { namespace = "aws:elasticbeanstalk:healthreporting:system", name = "SystemType", value = "enhanced" },
  ]

  env_var_settings = [
    for k, v in var.env_vars : { namespace = "aws:elasticbeanstalk:application:environment", name = k, value = v }
  ]
}

resource "aws_elastic_beanstalk_environment" "this" {
  name                = "${var.name}-env"
  application         = aws_elastic_beanstalk_application.this.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.this.name
  tier                = "WebServer"

  # A dynamic block generates one `setting { ... }` block per list item.
  dynamic "setting" {
    for_each = concat(local.base_settings, local.env_var_settings)

    content {
      namespace = setting.value.namespace
      name      = setting.value.name
      value     = setting.value.value
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.instance,
    aws_iam_role_policy_attachment.service,
  ]
}
