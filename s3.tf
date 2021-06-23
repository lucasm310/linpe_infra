resource "aws_s3_bucket" "bucket_linpe_documentos" {
  bucket        = "linpe-documentos-${terraform.workspace}"
  acl           = "private"
  force_destroy = true
  tags          = merge(var.tags, { enviroment = terraform.workspace })
}

resource "aws_s3_bucket" "linpe_site" {
  bucket        = "linpe-site-${terraform.workspace}"
  acl           = "private"
  force_destroy = true
  policy        = <<EOF
{
  "Id": "bucket_policy_site-${terraform.workspace}",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "bucket_policy_site_root-${terraform.workspace}",
      "Action": ["s3:ListBucket"],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::linpe-site-${terraform.workspace}",
      "Principal": {"AWS":"${aws_cloudfront_origin_access_identity.site.iam_arn}"}
    },
    {
      "Sid": "bucket_policy_site_all-${terraform.workspace}",
      "Action": ["s3:GetObject"],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::linpe-site-${terraform.workspace}/*",
      "Principal": {"AWS":"${aws_cloudfront_origin_access_identity.site.iam_arn}"}
    }
  ]
}
EOF
  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  tags = merge(var.tags, { enviroment = terraform.workspace })
}

resource "aws_s3_bucket" "linpe_app" {
  bucket        = "linpe-app-${terraform.workspace}"
  acl           = "private"
  force_destroy = true
  policy        = <<EOF
{
  "Id": "bucket_policy_app-${terraform.workspace}",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "bucket_policy_app_root-${terraform.workspace}",
      "Action": ["s3:ListBucket"],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::linpe-app-${terraform.workspace}",
      "Principal": {"AWS":"${aws_cloudfront_origin_access_identity.app.iam_arn}"}
    },
    {
      "Sid": "bucket_policy_app_all-${terraform.workspace}",
      "Action": ["s3:GetObject"],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::linpe-app-${terraform.workspace}/*",
      "Principal": {"AWS":"${aws_cloudfront_origin_access_identity.app.iam_arn}"}
    }
  ]
}
EOF
  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  tags = merge(var.tags, { enviroment = terraform.workspace })
}
