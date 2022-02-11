# S3 Gateway endpoint for private subnets
resource "aws_vpc_endpoint" "WebApps-GWendpS3" {
  service_name      = "com.amazonaws.${var.REGION}.s3"
  vpc_id            = aws_vpc.WebApps-vpc.id
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.WebApps-RTnat.id]

  tags = { Name = "WP01-GWendpS3" }
}

# Bucket
resource "aws_s3_bucket" "WP01-s3b" {
  bucket        = var.WP01_BUCKET_NAME
  acl           = "public-read"
  force_destroy = true

  tags = { Name = "WP01-s3b" }
}

# IAM user for bucket access
resource "aws_iam_user" "WP01-IAMuser" {
  name = "wp01-iam"
  tags = { Name = "WP01-IAMuser" }
}

# Access key
resource "aws_iam_access_key" "WP01-IAMkey" {
  user = aws_iam_user.WP01-IAMuser.name
}

# Policy
resource "aws_iam_user_policy" "WebApps-S3IAMpolicy" {
  name = "WebAppsS3IAMpolicy"
  user = aws_iam_user.WP01-IAMuser.name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.WP01-s3b.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.WP01-s3b.bucket}/*"
        ]
      }
    ]
  })
}