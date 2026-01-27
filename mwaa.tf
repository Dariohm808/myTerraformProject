# MWAA (Managed Workflows for Apache Airflow) Configuration

# VPC for MWAA (MWAA requires a VPC with private subnets)
resource "aws_vpc" "mwaa_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "mwaa-vpc"
    Environment = var.environment_tag
  }
}

#Need two private subnets for MWAA
# Private subnet 1
resource "aws_subnet" "mwaa_private_1" {
  vpc_id            = aws_vpc.mwaa_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "mwaa-private-subnet-1"
    Environment = var.environment_tag
  }
}

# Private subnet 2
resource "aws_subnet" "mwaa_private_2" {
  vpc_id            = aws_vpc.mwaa_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "mwaa-private-subnet-2"
    Environment = var.environment_tag
  }
}

# Public subnet for NAT Gateway
resource "aws_subnet" "mwaa_public" {
  vpc_id                  = aws_vpc.mwaa_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "mwaa-public-subnet"
    Environment = var.environment_tag
  }
}

# Internet Gateway
resource "aws_internet_gateway" "mwaa_igw" {
  vpc_id = aws_vpc.mwaa_vpc.id

  tags = {
    Name        = "mwaa-igw"
    Environment = var.environment_tag
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "mwaa_nat_eip" {
  domain = "vpc"

  tags = {
    Name        = "mwaa-nat-eip"
    Environment = var.environment_tag
  }

  depends_on = [aws_internet_gateway.mwaa_igw]
}

# NAT Gateway (allows private subnets to access internet)
resource "aws_nat_gateway" "mwaa_nat" {
  allocation_id = aws_eip.mwaa_nat_eip.id
  subnet_id     = aws_subnet.mwaa_public.id

  tags = {
    Name        = "mwaa-nat"
    Environment = var.environment_tag
  }

  depends_on = [aws_internet_gateway.mwaa_igw]
}

# Route table for public subnet
resource "aws_route_table" "mwaa_public_rt" {
  vpc_id = aws_vpc.mwaa_vpc.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.mwaa_igw.id
  }

  tags = {
    Name        = "mwaa-public-rt"
    Environment = var.environment_tag
  }
}

# Route table association for public subnet
resource "aws_route_table_association" "mwaa_public_rta" {
  subnet_id      = aws_subnet.mwaa_public.id
  route_table_id = aws_route_table.mwaa_public_rt.id
}

# Route table for private subnets (routes through NAT)
resource "aws_route_table" "mwaa_private_rt" {
  vpc_id = aws_vpc.mwaa_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.mwaa_nat.id
  }

  tags = {
    Name        = "mwaa-private-rt"
    Environment = var.environment_tag
  }
}

# Route table associations for private subnets
resource "aws_route_table_association" "mwaa_private_1_rta" {
  subnet_id      = aws_subnet.mwaa_private_1.id
  route_table_id = aws_route_table.mwaa_private_rt.id
}

resource "aws_route_table_association" "mwaa_private_2_rta" {
  subnet_id      = aws_subnet.mwaa_private_2.id
  route_table_id = aws_route_table.mwaa_private_rt.id
}

# Security group for MWAA
resource "aws_security_group" "mwaa_sg" {
  name_prefix = "mwaa-"
  description = "Security group for MWAA environment"
  vpc_id      = aws_vpc.mwaa_vpc.id

  # Allow inbound traffic within the security group
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Allow outbound traffic to all destinations (needed for package installation, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "mwaa-sg"
    Environment = var.environment_tag
  }
}

# S3 bucket for MWAA DAGs and logs
resource "aws_s3_bucket" "mwaa_bucket" {
  bucket = var.mwaa_dags_bucket_name

  tags = {
    Name        = "MWAA DAGs and Logs"
    Environment = var.environment_tag
  }
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "mwaa_bucket_pab" {
  bucket = aws_s3_bucket.mwaa_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role for MWAA execution
resource "aws_iam_role" "mwaa_execution_role" {
  name_prefix = "mwaa-execution-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "airflow.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment_tag
  }
}

# IAM policy for MWAA to access S3
resource "aws_iam_role_policy" "mwaa_s3_policy" {
  name_prefix = "mwaa-s3-policy-"
  role        = aws_iam_role.mwaa_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.mwaa_bucket.arn,
          "${aws_s3_bucket.mwaa_bucket.arn}/*"
        ]
      }
    ]
  })
}

# IAM policy for MWAA CloudWatch Logs
resource "aws_iam_role_policy" "mwaa_logs_policy" {
  name_prefix = "mwaa-logs-policy-"
  role        = aws_iam_role.mwaa_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:GetLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/airflow/*"
      }
    ]
  })
}

# MWAA Environment
resource "aws_mwaa_environment" "mwaa" {
  name              = var.mwaa_environment_name
  airflow_version   = "2.6.3"
  environment_class = "mw1.small"
  execution_role_arn = aws_iam_role.mwaa_execution_role.arn
  source_bucket_arn = aws_s3_bucket.mwaa_bucket.arn
  dag_s3_path       = "dags"
  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }
    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }
    task_logs {
      enabled   = true
      log_level = "INFO"
    }
    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }
  }

  max_workers = var.mwaa_max_workers
  min_workers = var.mwaa_min_workers

  network_configuration {
    subnet_ids            = [aws_subnet.mwaa_private_1.id, aws_subnet.mwaa_private_2.id]
    security_group_ids    = [aws_security_group.mwaa_sg.id]
  }

  tags = {
    Name        = var.mwaa_environment_name
    Environment = var.environment_tag
  }

  depends_on = [
    aws_iam_role_policy.mwaa_s3_policy,
    aws_iam_role_policy.mwaa_logs_policy
  ]
}

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Outputs
output "mwaa_webserver_url" {
  description = "The webserver URL of the MWAA environment"
  value       = aws_mwaa_environment.mwaa.webserver_url
}

output "mwaa_environment_arn" {
  description = "The ARN of the MWAA environment"
  value       = aws_mwaa_environment.mwaa.arn
}

output "mwaa_dags_bucket" {
  description = "S3 bucket for DAGs and logs"
  value       = aws_s3_bucket.mwaa_bucket.id
}
