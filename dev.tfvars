TAG_ENV = terraform.workspace

REGION             = "us-west-2"
VPC_NET            = "10.99.0.0/18"
VPC_AZS            = ["us-west-2a", "us-west-2b"]
VPC_PUBLIC_SUBNETS = ["10.99.1.0/24", "10.99.2.0/24"]
VPC_PRIVATE_SUBNETS = { "APPa" = "10.99.21.0/24", "APPb" = "10.99.22.0/24",
"RDSa" = "10.99.31.0/24", "RDSb" = "10.99.32.0/24" }

WP01_BUCKET_NAME = "wp01-s3b-${terraform.workspace}"

#SSH_PUB_KEY = ""