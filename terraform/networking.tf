# ─── VPC ────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "security-lab-vpc"
  })
}

# ─── VPC FLOW LOGS ──────────────────────────────────
resource "aws_flow_log" "main" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  iam_role_arn         = aws_iam_role.web_server.arn
  log_destination      = aws_s3_bucket.log_bucket.arn
  log_destination_type = "s3"
}

# ─── SUBNETS ────────────────────────────────────────
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false # never auto-assign public IPs

  tags = merge(local.common_tags, {
    Name = "public-subnet"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"


  tags = merge(local.common_tags, {
    Name = "private-subnet"
    Tier = "private"
  })
}

# ─── INTERNET GATEWAY ───────────────────────────────
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, { Name = "main-igw" })
}

# ─── ROUTE TABLES ───────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, { Name = "public-rt" })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ─── DEFAULT SG — locked down ───────────────────────
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
}

# ─── SECURITY GROUPS ────────────────────────────────
resource "aws_security_group" "web" {
  #checkov:skip=CKV2_AWS_5: "No EC2 instances in phase 11 — attached in phase 12"
  name        = "web-servers-sg"
  description = "Web tier — HTTPS only inbound"
  vpc_id      = aws_vpc.main.id


  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #  description = "HTTP redirect"
  # from_port   = 80
  #to_port     = 80
  # protocol    = "tcp"
  # cidr_blocks = ["0.0.0.0/0"]
  #}

  # ingress {
  # description = "SSH from office only"
  # from_port   = 22
  # to_port     = 22
  # protocol    = "tcp"
  # cidr_blocks = ["10.0.0.0/8"]  # internal only
  #}

  # egress {
  #  description = "Allow all outbound"
  #  from_port   = 0
  #  to_port     = 0
  #  protocol    = "-1"
  #  cidr_blocks = ["0.0.0.0/0"]
  #}

  egress {
    description = "HTTPS outbound only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP outbound for package installs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = merge(local.common_tags, { Name = "web-sg" })
}

# ─── DATABASE SECURITY GROUP ────────────────────────
resource "aws_security_group" "database" {
  #checkov:skip=CKV2_AWS_5: "No RDS instances in phase 11 — attached in phase 12"
  name        = "database-sg"
  description = "DB tier — PostgreSQL from web SG only, no public access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from web tier only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description     = "PostgreSQL replies to web tier only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  #  egress {
  #    from_port   = 0
  #    to_port     = 0
  #    protocol    = "-1"
  #    cidr_blocks = ["0.0.0.0/0"]
  #  }

  tags = merge(local.common_tags, { Name = "db-sg" })
}

# ─── FIX 3: CKV_AWS_130 — VPC no default SG ─────────
#resource "aws_default_security_group" "default" {
#  vpc_id = aws_vpc.main.id
# No ingress or egress rules — locked down default SG
#}
