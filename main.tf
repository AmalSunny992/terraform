resource "aws_s3_bucket" "tf_bkt" {
  bucket = var.my_bucket_name
  }

resource "aws_s3_bucket_ownership_controls" "terraform_demo" {
  bucket = aws_s3_bucket.tf_bkt.id
    rule {
    object_ownership = "BucketOwnerPreferred"
  }
  }

resource "aws_s3_bucket_public_access_block" "terraform_demo" {
  bucket = aws_s3_bucket.tf_bkt.id
  
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "terraform_demo" {
  depends_on = [aws_s3_bucket_ownership_controls.terraform_demo,
                aws_s3_bucket_public_access_block.terraform_demo,
  ]

  bucket = aws_s3_bucket.tf_bkt.id
  acl    = "public-read"
}


resource "aws_s3_bucket_policy" "host_bucket_policy" {
  bucket = aws_s3_bucket.tf_bkt.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
        {
            "Effect" : "Allow",
             "Principal": "*",
            "Action": [
                "s3:*"
            ],
            "Resource" : [
                "arn:aws:s3:::${var.my_bucket_name}",
                "arn:aws:s3:::${var.my_bucket_name}/*" 
            ]
        }
    ]
  })
}

module "template_files" {
  source = "hashicorp/dir/template"
  base_dir = "${path.module}/<web-files>"
}

resource "aws_s3_bucket_website_configuration" "web-config" {
  bucket = aws_s3_bucket.tf_bkt.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error"
  } 
}

resource "aws_s3_bucket_object" "Bucket_files" {
  bucket = aws_s3_bucket.tf_bkt.id
  for_each = module.template_files.files
  key    = each.key
  content_type = each.value.content_type
  source = each.value.source_path
  content = each.value.content
  etag = each.value.digests.md5
}