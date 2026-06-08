# tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "first_bucket" {
  #checkov:skip=CKV_AWS_144: "Cross-region replication not supported in LocalStack"
  #checkov:skip=CKV_AWS_145: "KMS not supported in LocalStack, using AES256"
  #checkov:skip=CKV2_AWS_62: "Event notifications not supported in LocalStack"
  #checkov:skip=CKV2_AWS_61: "Lifecycle managed separately below"
  bucket = "my-first-terraform-bucket"

  tags = {
    Name        = "first-bucket"
    Environment = "learning"
    Phase       = "11"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "first_bucket" {
  bucket = aws_s3_bucket.first_bucket.id
  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "first_bucket" {
  bucket = aws_s3_bucket.first_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "first_bucket" {
  bucket                  = aws_s3_bucket.first_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "first_bucket" {
  bucket        = aws_s3_bucket.first_bucket.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "first-bucket-logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "first_bucket" {
  bucket = aws_s3_bucket.first_bucket.id
  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    filter {}

    expiration {
      days = 365
    }
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "security-hardening"
    Phase       = "11"
  }
}
