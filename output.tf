output "ec2nat_public_ip" {
  description = "Public IP address of NAT (Bastion host) instance"
  value       = aws_instance.WebApps-EC2nat.public_ip
}

output "alb_dns_name" {
  description = "Public DNS name of Application Load Balancer"
  value       = aws_lb.WP01-ALB.dns_name
}

output "rds_address" {
  description = "Private address of RDS MySQL DB"
  value       = aws_db_instance.rds01.address
}

output "efs_id" {
  description = "EFS ID"
  value       = aws_efs_file_system.WP01-EFS.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.WP01-s3b.bucket
}

output "s3_iam_user_name" {
  value = aws_iam_user.WP01-IAMuser.name
}

output "s3_iam_user_key" {
  value = aws_iam_access_key.WP01-IAMkey.id
}

output "s3_iam_user_secret" {
  value     = aws_iam_access_key.WP01-IAMkey.encrypted_secret
  sensitive = true
}

output "INFO" {
  value = "IAM user secret can be displayed with `terraform output -raw s3_iam_user_secret` command"
}