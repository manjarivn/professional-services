provider "aws" {
  region  = "us-east-1"
}

resource "aws_kms_key" "billing_key" {
  description             = "KMS key used for Billing Project"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "ampricing" {
  bucket = "${var.billingbucket}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.billing_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Effect": "Allow",
    "Principal": {
      "Service": "billingreports.amazonaws.com"
    },
    "Action": [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy"
    ],
    "Resource": "arn:aws:s3:::${var.billingbucket}"
  },
  {
    "Effect": "Allow",
    "Principal": {
      "Service": "billingreports.amazonaws.com"
    },
    "Action": "s3:PutObject",
    "Resource": "arn:aws:s3:::${var.billingbucket}/*"
  }
  ]
}
POLICY
}

resource "aws_cur_report_definition" "ampricing" {
  report_name                = "ampricing"
  time_unit                  = "DAILY"
  format                     = "textORcsv"
  compression                = "GZIP"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                  = "${var.billingbucket}"
  s3_prefix                  = "account"
  s3_region                  = "us-east-1"
  additional_artifacts       = []
}

output "billingbucket" {
  value = "${var.billingbucket}"
}