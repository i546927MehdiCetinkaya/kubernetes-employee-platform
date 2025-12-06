# OpenVPN EC2 Server Module
# Cost-effective VPN solution using EC2 with OpenVPN Access Server

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for OpenVPN
resource "aws_security_group" "openvpn" {
  name        = "${var.project_name}-openvpn-sg"
  description = "Security group for OpenVPN server"
  vpc_id      = var.vpc_id

  # OpenVPN UDP (default)
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "OpenVPN UDP"
  }

  # OpenVPN TCP (fallback)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "OpenVPN TCP / Admin Web UI"
  }

  # SSH for management (optional, can be restricted)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
    description = "SSH access"
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name        = "${var.project_name}-openvpn-sg"
    Environment = var.environment
  }
}

# IAM Role for OpenVPN server
resource "aws_iam_role" "openvpn" {
  name = "${var.project_name}-openvpn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-openvpn-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "openvpn_ssm" {
  name = "${var.project_name}-openvpn-ssm-policy"
  role = aws_iam_role.openvpn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:PutParameter"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/${var.project_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/${aws_route53_zone.private.zone_id}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "openvpn_ssm_managed" {
  role       = aws_iam_role.openvpn.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "openvpn" {
  name = "${var.project_name}-openvpn-profile"
  role = aws_iam_role.openvpn.name
}

# Elastic IP for OpenVPN
resource "aws_eip" "openvpn" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-openvpn-eip"
    Environment = var.environment
  }
}

# OpenVPN EC2 Instance
resource "aws_instance" "openvpn" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.openvpn.id]
  iam_instance_profile        = aws_iam_instance_profile.openvpn.name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    project_name    = var.project_name
    domain_name     = var.domain_name
    vpc_cidr        = var.vpc_cidr
    vpn_client_cidr = var.vpn_client_cidr
    dns_server      = cidrhost(var.vpc_cidr, 2)
    hr_portal_ip    = var.hr_portal_ip
    api_ip          = var.api_ip
    hosted_zone_id  = aws_route53_zone.private.zone_id
    admin_password  = var.admin_password
  }))

  tags = {
    Name        = "${var.project_name}-openvpn"
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# Associate EIP with instance
resource "aws_eip_association" "openvpn" {
  instance_id   = aws_instance.openvpn.id
  allocation_id = aws_eip.openvpn.id
}

# Route 53 Private Hosted Zone
resource "aws_route53_zone" "private" {
  name = var.domain_name

  vpc {
    vpc_id = var.vpc_id
  }

  tags = {
    Name        = "${var.project_name}-private-zone"
    Environment = var.environment
  }
}

# DNS Records for HR Portal
resource "aws_route53_record" "hr_portal" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "hrportal.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [var.hr_portal_ip]
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [var.api_ip]
}

# Public DNS record for VPN server
resource "aws_route53_record" "vpn" {
  count   = var.public_hosted_zone_id != "" ? 1 : 0
  zone_id = var.public_hosted_zone_id
  name    = "vpn.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.openvpn.public_ip]
}

# Store VPN config in SSM
resource "aws_ssm_parameter" "vpn_server_ip" {
  name        = "/${var.project_name}/vpn/server-ip"
  description = "OpenVPN Server Public IP"
  type        = "String"
  value       = aws_eip.openvpn.public_ip

  tags = {
    Name        = "${var.project_name}-vpn-server-ip"
    Environment = var.environment
  }
}
