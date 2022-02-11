###############################################################################
# PROVIDER
###############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 4.0.0"
    }
  }
}

provider "aws" {
  profile = var.PROFILE
  region  = var.REGION

  default_tags {
    tags = {
      Scope = var.TAG_SCOPE
      Env   = var.TAG_ENV
    }
  }
}

###############################################################################
# NETWORK
###############################################################################

# Network related resources are located in the `network.tf`

###############################################################################
# DATABASE
###############################################################################

resource "aws_db_subnet_group" "WebApps-RDSsubn1" {
  name        = "webapps-rdssubn1"
  description = "RDS subnet for WebApps"
  subnet_ids = [for SubN in keys(var.VPC_PRIVATE_SUBNETS) : aws_subnet.WebApps-SubNprivate["${SubN}"].id
  if replace(SubN, "/.$/", "") == "RDS"]

  tags = { Name = "WebApps-RDSsubn1" }
}

resource "aws_db_instance" "rds01" {
  db_subnet_group_name       = aws_db_subnet_group.WebApps-RDSsubn1.name
  engine                     = "mysql"
  engine_version             = "5.7"
  allocated_storage          = 5
  instance_class             = var.RDS01_INST_CLASS
  identifier                 = var.RDS01_INST_NAME
  username                   = var.RDS01_MASTER_USER
  password                   = var.RDS01_MASTER_PASSWORD
  name                       = var.RDS01_DB01_NAME
  multi_az                   = "false" # no replica because of Free Tier
  publicly_accessible        = "false"
  availability_zone          = var.VPC_AZS[0]
  vpc_security_group_ids     = [aws_security_group.WebApps-SGprivate.id]
  backup_retention_period    = 0 # no backups because of limited snapshot space
  backup_window              = "00:00-03:00"
  auto_minor_version_upgrade = "true" # auto updates
  maintenance_window         = "Mon:03:00-Mon:06:00"
  skip_final_snapshot        = "true"

  tags = { Name = var.RDS01_INST_NAME }
}

###############################################################################
# EFS
###############################################################################

# EFS for Wordpress dynamic content
resource "aws_efs_file_system" "WP01-EFS" {
  creation_token = "wp01-efs"

  tags = { Name = "WP01-EFS" }
}

# Mountpoints in APP subnets
resource "aws_efs_mount_target" "WP01-MTa" {
  file_system_id  = aws_efs_file_system.WP01-EFS.id
  subnet_id       = aws_subnet.WebApps-SubNprivate["APPa"].id
  security_groups = [aws_security_group.WebApps-SGprivate.id]
}
resource "aws_efs_mount_target" "WP01-MTb" {
  file_system_id  = aws_efs_file_system.WP01-EFS.id
  subnet_id       = aws_subnet.WebApps-SubNprivate["APPb"].id
  security_groups = [aws_security_group.WebApps-SGprivate.id]
}

###############################################################################
# NAT INSTANCE
###############################################################################

# Key pair
resource "aws_key_pair" "WebApps-KeyPair" {
  key_name   = "WebApps-key"
  public_key = var.SSH_PUB_KEY

  tags = { Name = "WebApps-KeyPair" }
}

# Select the newest AMI with Amazon Linux NAT instance
data "aws_ami" "AmazonLinuxNAT" {
  most_recent = true
  owners      = ["137112412989"] # Amazon
  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-*-x86_64-ebs"]
  }
}

# NAT instance
# Inject variables into template script to create Wordpress MySQL account
# and construct Wordpress suite on EFS
resource "aws_instance" "WebApps-EC2nat" {
  ami               = data.aws_ami.AmazonLinuxNAT.id
  availability_zone = var.VPC_AZS[0]
  instance_type     = "t2.micro"
  key_name          = aws_key_pair.WebApps-KeyPair.key_name
  depends_on        = [aws_db_instance.rds01, aws_efs_file_system.WP01-EFS]

  user_data = templatefile(
    "${path.module}/ec2nat_user_data.tftpl", {
      RDS_ADDRESS         = aws_db_instance.rds01.address
      RDS_MASTER_USER     = var.RDS01_MASTER_USER
      RDS_MASTER_PASSWORD = var.RDS01_MASTER_PASSWORD
      RDS_DB_NAME         = var.RDS01_DB01_NAME
      RDS_DB_USER         = var.RDS01_WP01_USER
      RDS_DB_PASSWORD     = var.RDS01_WP01_PASSWORD
      EFS_ID              = aws_efs_file_system.WP01-EFS.id
      PLUGIN_FILENAME     = var.WP_PLUGIN_FILENAME
      WP_AUTH_KEY         = var.WP01_AUTH_KEY
      WP_SECURE_AUTH_KEY  = var.WP01_SECURE_AUTH_KEY
      WP_LOGGED_IN_KEY    = var.WP01_LOGGED_IN_KEY
      WP_NONCE_KEY        = var.WP01_NONCE_KEY
      WP_AUTH_SALT        = var.WP01_AUTH_SALT
      WP_SECURE_AUTH_SALT = var.WP01_SECURE_AUTH_SALT
      WP_LOGGED_IN_SALT   = var.WP01_LOGGED_IN_SALT
      WP_NONCE_SALT       = var.WP01_NONCE_SALT
    }
  )

  network_interface {
    network_interface_id = aws_network_interface.WebApps-NATeni.id
    device_index         = 0
  }

  root_block_device {
    volume_size = 8
  }

  # Do not recreate NAT instance because of new latest AMI
  lifecycle {
    ignore_changes = [ami, user_data]
  }

  tags = { Name = "WebApps-EC2nat" }
}

###############################################################################
# AUTOSCALING GROUP AND ALB
###############################################################################

# Autoscaling group related resources are located in the `autoscaling.tf`

###############################################################################
# S3
###############################################################################

# S3 related resources are located in the `s3.tf`

###############################################################################
# MONITORING
###############################################################################

# Monitoring related resources are located in the `monitoring.tf`

###############################################################################
# BACKUPS
###############################################################################

# Backups ommited because of free tier test envenvironment