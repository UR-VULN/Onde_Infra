# S3용 KMS키

resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name    = "onde-s3-kms-key"
    Project = "onde"
  }
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/onde-s3-key"
  target_key_id = aws_kms_key.s3_key.key_id
}

# RDS용 KMS키
resource "aws_kms_key" "rds_key" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name    = "onde-rds-kms-key"
    Project = "onde"
  }
}

resource "aws_kms_alias" "rds_key_alias" {
  name          = "alias/onde-rds-key"
  target_key_id = aws_kms_key.rds_key.key_id
}