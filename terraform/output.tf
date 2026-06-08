output "bucket_id" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.data_bucket.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.data_bucket.arn
}

output "encryption_status" {
  description = "Encryption algorithm in use"
  value       = "AES256"
}
