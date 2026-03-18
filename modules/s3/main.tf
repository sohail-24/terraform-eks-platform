############################################
# S3 Bucket
############################################

resource "aws_s3_bucket" "django_media" {
  bucket = var.bucket_name
  
  force_destroy = true  # ✅ ADD THIS LINE

  tags = {
    Name        = "django-media-storage"
    Environment = "dev"
  }
}

############################################
# Ownership (Disable ACLs - modern AWS)
############################################

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.django_media.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

############################################
# Versioning
############################################

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.django_media.id

  versioning_configuration {
    status = "Enabled"
  }
}

############################################
# Public Access Block (IMPORTANT FIX)
############################################

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.django_media.id

  block_public_acls       = true
  ignore_public_acls      = true

  block_public_policy     = false   # ✅ allow bucket policy
  restrict_public_buckets = false   # ✅ allow public access
}

############################################
# Bucket Policy (PUBLIC READ)
############################################

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.django_media.id

  depends_on = [
    aws_s3_bucket_public_access_block.block_public
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadAccess"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.django_media.arn}/*"
      }
    ]
  })
}

############################################
# Lifecycle (AUTO DELETE versions)
############################################

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.django_media.id

  rule {
    id     = "delete-all-versions"
    status = "Enabled"

    filter {}   # ✅ ADD THIS LINE (IMPORTANT)

    expiration {
      days = 1
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}
