data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  az             = var.availability_zone != "" ? var.availability_zone : data.aws_availability_zones.available.names[0]
  cloud_native   = var.secrets_backend == "cloud_native"
  cn_secret_name = "${var.name_prefix}-stack"

  supabase_public_url = "http://${aws_eip.this.public_ip}:8000"
  site_url            = "http://${aws_eip.this.public_ip}:${var.web_http_port}"

  cloud_native_access = local.cloud_native ? {
    provider    = "aws"
    region      = var.region
    secret_name = local.cn_secret_name
  } : null
}

# --- Network ---

resource "aws_vpc" "this" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.name_prefix}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-igw" })
}

resource "aws_subnet" "this" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.42.1.0/24"
  availability_zone       = local.az
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-subnet" })
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-rt" })
}

resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-sg"
  description = "RecoverySearch stack ingress"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-sg" })

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  dynamic "ingress" {
    for_each = toset(["80", "443", "3000", "8000", "8443"])
    content {
      description = "web-${ingress.value}"
      from_port   = tonumber(ingress.value)
      to_port     = tonumber(ingress.value)
      protocol    = "tcp"
      cidr_blocks = [var.web_allowed_cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "this" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name_prefix}-eip" })
}

resource "aws_key_pair" "this" {
  key_name   = "${var.name_prefix}-key"
  public_key = var.ssh_public_key
  tags       = var.tags
}

# --- Cloud-native secrets (Secrets Manager + instance role) ---

resource "aws_secretsmanager_secret" "stack" {
  count = local.cloud_native ? 1 : 0

  name        = local.cn_secret_name
  description = "RecoverySearch self-hosted Supabase stack secrets."
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "stack" {
  count = local.cloud_native ? 1 : 0

  secret_id     = aws_secretsmanager_secret.stack[0].id
  secret_string = jsonencode(var.secret_values)
}

data "aws_iam_policy_document" "assume" {
  count = local.cloud_native ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vm" {
  count = local.cloud_native ? 1 : 0

  name               = "${var.name_prefix}-vm"
  assume_role_policy = data.aws_iam_policy_document.assume[0].json
  tags               = var.tags
}

data "aws_iam_policy_document" "read_secret" {
  count = local.cloud_native ? 1 : 0

  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.stack[0].arn]
  }
}

resource "aws_iam_role_policy" "read_secret" {
  count = local.cloud_native ? 1 : 0

  name   = "${var.name_prefix}-read-secret"
  role   = aws_iam_role.vm[0].id
  policy = data.aws_iam_policy_document.read_secret[0].json
}

resource "aws_iam_instance_profile" "vm" {
  count = local.cloud_native ? 1 : 0

  name = "${var.name_prefix}-vm"
  role = aws_iam_role.vm[0].name
}

# --- Bootstrap ---

module "bootstrap" {
  source = "../bootstrap"

  supabase_public_url      = local.supabase_public_url
  site_url                 = local.site_url
  additional_redirect_urls = var.additional_redirect_urls
  app_repo_url             = var.app_repo_url
  app_repo_ref             = var.app_repo_ref
  web_http_port            = var.web_http_port
  data_device              = "/dev/nvme1n1" # Nitro instances expose EBS as NVMe

  secrets_backend = var.secrets_backend
  vault           = try(var.external_secrets_access.vault, null)
  doppler         = try(var.external_secrets_access.doppler, null)
  cloud_native    = local.cloud_native_access
}

# --- Instance + data volume ---

resource "aws_instance" "this" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_size
  subnet_id                   = aws_subnet.this.id
  vpc_security_group_ids      = [aws_security_group.this.id]
  key_name                    = aws_key_pair.this.key_name
  availability_zone           = local.az
  iam_instance_profile        = local.cloud_native ? aws_iam_instance_profile.vm[0].name : null
  user_data                   = module.bootstrap.user_data
  user_data_replace_on_change = true

  root_block_device {
    volume_size = var.os_disk_size_gb
    volume_type = "gp3"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-vm" })
}

resource "aws_eip_association" "this" {
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this.id
}

resource "aws_ebs_volume" "data" {
  availability_zone = local.az
  size              = var.data_disk_size_gb
  type              = "gp3"
  tags              = merge(var.tags, { Name = "${var.name_prefix}-data" })
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.this.id
}

# --- Optional DNS ---

resource "aws_route53_record" "this" {
  count = var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.dns_record_name
  type    = "A"
  ttl     = 300
  records = [aws_eip.this.public_ip]
}
