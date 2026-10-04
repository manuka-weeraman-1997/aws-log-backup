# Example: S3 bucket as the final log archive, with a lifecycle policy that
# moves objects through progressively cheaper storage classes as they age.

resource "aws_s3_bucket" "logs" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "log-lifecycle"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    # Stage 1 (0-30 days): Standard - recent logs are the ones most likely
    # to be queried for debugging/incident investigation.

    # Stage 2 (30-90 days): Standard-IA - still millisecond retrieval, but
    # access is rare by now.
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Stage 3 (90-180 days): Glacier - kept for audit/compliance, not active
    # use; retrieval takes minutes-hours in exchange for much lower cost.
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Stage 4 (180+ days): Glacier Deep Archive - cheapest tier, for logs
    # that must be retained but are essentially never read.
    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }

    # Stage 5 (~7 years): expire - matches a typical compliance retention
    # window; retaining indefinitely is cost and liability with no benefit.
    expiration {
      days = 2555
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
