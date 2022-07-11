## AWS S3 Public Bucket

resource "aws_s3_bucket" "violations3" {
  name = "essehbee_sb_01_public"
}

resource "aws_s3_bucket_public_access_block" "aws_s3_bucket_public_access_block" {
  bucket = aws_s3_bucket.s3_bucket_public.id

  block_public_acls   = false
  block_public_policy = false
}

