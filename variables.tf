# `terra1-iam` is an account without web access. 
# It's a member of `terraform` group that has clone of SystemAdministrator, 
# NetworkAdministrator, DatabaseAdministrator, AmazonS3FullAccess,
# AmazonElasticFileSystemFullAccess and IAMFullAccess policies applied.
# With request condition `RequestedRegion` for N.Virginia and Oregon
variable "PROFILE" {
  default = "terra1-iam"
}

# VPC

variable "REGION" {
  default = "us-east-1"
}
variable "VPC_NET" {
  default = "10.98.0.0/18"
}
variable "VPC_AZS" {
  default = ["us-east-1a", "us-east-1b"]
}
variable "VPC_PUBLIC_SUBNETS" {
  default = ["10.98.1.0/24", "10.98.2.0/24"]
}
variable "VPC_PRIVATE_SUBNETS" {
  default = { "APPa" = "10.98.21.0/24", "APPb" = "10.98.22.0/24",
  "RDSa" = "10.98.31.0/24", "RDSb" = "10.98.32.0/24" }
}

# RDS

variable "RDS01_INST_NAME" {
  default = "webapps-db01"
}
variable "RDS01_INST_CLASS" {
  default = "db.t2.micro"
}
variable "RDS01_MASTER_USER" {
  default = "root"
}
variable "RDS01_DB01_NAME" {
  default = "wp01"
}
variable "RDS01_WP01_USER" {
  default = "wp01-user"
}
variable "RDS01_MASTER_PASSWORD" { sensitive = "true" }
variable "RDS01_WP01_PASSWORD" { sensitive = "true" }

# WORDPRESS

variable "WP01_ASG_MIN_INST" {
  default = 1
}
variable "WP01_ASG_MAX_INST" {
  default = 2
}
variable "WP01_INST_TYPE" {
  default = "t2.micro"
}
variable "WP_PLUGIN_FILENAME" {
  default = "w3-total-cache.2.2.1.zip"
}
variable "WP01_BUCKET_NAME" {
  default = "wp01-s3b"
}

variable "WP01_AUTH_KEY" { sensitive = "true" }
variable "WP01_SECURE_AUTH_KEY" { sensitive = "true" }
variable "WP01_LOGGED_IN_KEY" { sensitive = "true" }
variable "WP01_NONCE_KEY" { sensitive = "true" }
variable "WP01_AUTH_SALT" { sensitive = "true" }
variable "WP01_SECURE_AUTH_SALT" { sensitive = "true" }
variable "WP01_LOGGED_IN_SALT" { sensitive = "true" }
variable "WP01_NONCE_SALT" { sensitive = "true" }

# USABILITY

variable "EMAIL_ALERTS" {
  #  default = ""
}
variable "TAG_SCOPE" {
  default = "WebApps"
}
variable "TAG_ENV" {
  default = ""
}
variable "SSH_PUB_KEY" {
  #  default   = ""
  sensitive = "true"
}