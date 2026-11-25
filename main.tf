provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# Network: VPC, Internet Gateway, NAT Gateway, public and private subnets
# ---------------------------------------------------------------------------

module "vpc" {
  source     = "./vpc"
  cidr_block = "192.168.0.0/16"
  name       = "wordpress-vpc"
}

module "ig" {
  source = "./ig"
  vpc_id = module.vpc.id
  name   = "wordpress-igw"
}

module "public_subnets" {
  source   = "./subnet"
  for_each = local.public_subnets

  vpc_id                  = module.vpc.id
  map_public_ip_on_launch = true
  name                    = each.key
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
}

module "private_subnets" {
  source   = "./subnet"
  for_each = local.private_subnets

  vpc_id                  = module.vpc.id
  map_public_ip_on_launch = false
  name                    = each.key
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
}

# NAT Gateway in a public subnet gives private subnets outbound internet access.
module "nat_gw" {
  source     = "./nat"
  depends_on = [module.ig]
  subnet_id  = module.public_subnets["public_subnet_1"].id
  name       = "wordpress-nat-gw"
}

# Public subnets route 0.0.0.0/0 through the Internet Gateway.
module "public_rt" {
  source     = "./rt"
  vpc_id     = module.vpc.id
  cidr_block = "0.0.0.0/0"
  gateway_id = module.ig.id
  name       = "wordpress-public-rt"
}

# Private subnets route 0.0.0.0/0 through the NAT Gateway.
module "private_rt" {
  source     = "./rt"
  vpc_id     = module.vpc.id
  cidr_block = "0.0.0.0/0"
  gateway_id = module.nat_gw.id
  name       = "wordpress-private-rt"
}

resource "aws_route_table_association" "public" {
  for_each       = module.public_subnets
  subnet_id      = each.value.id
  route_table_id = module.public_rt.id
}

resource "aws_route_table_association" "private" {
  for_each       = module.private_subnets
  subnet_id      = each.value.id
  route_table_id = module.private_rt.id
}

# ---------------------------------------------------------------------------
# Security groups
# ---------------------------------------------------------------------------

module "wordpress_sg" {
  source      = "./sg"
  name        = "wordpress-sg"
  description = "Allow HTTP and HTTPS from the internet and SSH from an allowed CIDR"
  vpc_id      = module.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "web" {
  for_each = local.web_ingress_ports

  description       = "Allow inbound ${each.key}"
  security_group_id = module.wordpress_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = each.value
  to_port           = each.value
  ip_protocol       = "tcp"

  tags = {
    Name = "allow-${each.key}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  description       = "Allow inbound SSH from the allowed CIDR only"
  security_group_id = module.wordpress_sg.id
  cidr_ipv4         = var.ssh_allowed_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"

  tags = {
    Name = "allow-ssh"
  }
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = module.wordpress_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = {
    Name = "allow-all-outbound"
  }
}

module "rds_sg" {
  source      = "./sg"
  name        = "rds-sg"
  description = "Allow MySQL only from wordpress-sg"
  vpc_id      = module.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "mysql_from_wordpress" {
  security_group_id            = module.rds_sg.id
  referenced_security_group_id = module.wordpress_sg.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"

  tags = {
    Name = "allow-mysql-from-wordpress-sg"
  }
}

# ---------------------------------------------------------------------------
# Compute: WordPress on EC2 (public subnet)
# ---------------------------------------------------------------------------

module "webserver" {
  source                 = "./ec2"
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [module.wordpress_sg.id]
  subnet_id              = module.public_subnets["public_subnet_1"].id
  user_data              = file("${path.module}/scripts/user_data.sh")
  name                   = "wordpress-ec2"
}

# ---------------------------------------------------------------------------
# Database: RDS MySQL (private subnets, not publicly accessible)
# ---------------------------------------------------------------------------

resource "aws_db_subnet_group" "mysql" {
  name       = "wordpress-mysql-subnet-group"
  subnet_ids = [for subnet in module.private_subnets : subnet.id]

  tags = {
    Name = "wordpress-mysql-subnet-group"
  }
}

module "rds" {
  source = "./rds"

  identifier             = "wordpress-mysql"
  engine                 = "mysql"
  engine_version         = var.db_engine_version
  instance_class         = "db.t3.micro"
  allocated_storage      = "20"
  storage_type           = "gp2"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  vpc_security_group_ids = [module.rds_sg.id]
  skip_final_snapshot    = true
  name                   = "wordpress-mysql"
}
