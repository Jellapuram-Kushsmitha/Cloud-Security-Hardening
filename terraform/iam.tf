# ─── GROUPS ─────────────────────────────────────────
resource "aws_iam_group" "developers" {
  name = "developers"
}

resource "aws_iam_group" "security_team" {
  name = "security-team"
}

# ─── USERS ──────────────────────────────────────────
resource "aws_iam_user" "alice" {
  #checkov:skip=CKV_AWS_273: "SSO not available in LocalStack"
  name = "alice"
  tags = local.common_tags
}

resource "aws_iam_user" "bob" {
  #checkov:skip=CKV_AWS_273: "SSO not available in LocalStack"
  name = "bob"
  tags = local.common_tags
}

# ─── GROUP MEMBERSHIPS ──────────────────────────────
resource "aws_iam_group_membership" "dev_members" {
  name  = "dev-team-membership"
  group = aws_iam_group.developers.name
  users = [aws_iam_user.alice.name]
}

resource "aws_iam_group_membership" "sec_members" {
  name  = "sec-team-membership"
  group = aws_iam_group.security_team.name
  users = [aws_iam_user.bob.name]
}

# ─── POLICIES ───────────────────────────────────────
resource "aws_iam_policy" "s3_read_only" {
  name        = "S3ReadOnlyPolicy"
  description = "Read-only access to data bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.data_bucket.arn,
        "${aws_s3_bucket.data_bucket.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_policy" "deny_iam_writes" {
  name        = "DenyIAMWrites"
  description = "Prevent privilege escalation"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Deny"
      Action = [
        "iam:Attach*", "iam:Create*",
        "iam:Delete*", "iam:Detach*",
        "iam:Put*", "iam:Update*"
      ]
      Resource = "*"
    }]
  })
}

# ─── S3 LIFECYCLE (fixes CKV_AWS_300) ───────────────
resource "aws_s3_bucket_lifecycle_configuration" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id

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

# ─── POLICY ATTACHMENTS ─────────────────────────────
resource "aws_iam_group_policy_attachment" "dev_s3" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_read_only.arn
}

resource "aws_iam_group_policy_attachment" "dev_deny_iam" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.deny_iam_writes.arn
}

# ─── EC2 ROLE ────────────────────────────────────────
resource "aws_iam_role" "web_server" {
  name = "WebServerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "web_server" {
  name = "WebServerPermissions"
  role = aws_iam_role.web_server.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.data_bucket.arn,
        "${aws_s3_bucket.data_bucket.arn}/*"
      ]
    }]
  })
}
