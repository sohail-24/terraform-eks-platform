output "bucket_name" {
  value = aws_s3_bucket.django_media.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.django_media.arn
}

