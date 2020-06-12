provider "aws"{
	region ="ap-south-1"
	profile="gopalprofile"
	}

resource "aws_s3_bucket" "b" {
  bucket = "mytasklnct"
  acl    = "public-read"
 
 
}

resource "aws_s3_bucket_object" "object" {
  depends_on=[aws_s3_bucket.b]  
  bucket = aws_s3_bucket.b.bucket
  key    = "ironman.jpg"
  source = "C:/Users/gopal/Desktop/Iron_Man.jpg"
  acl ="public-read"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "mytasklnct.s3.amazonaws.com"
    origin_id   = "S3-mytasklnct"
   custom_origin_config {
     http_port=80
     https_port=80
     origin_protocol_policy="match-viewer"
     origin_ssl_protocols=["TLSv1", "TLSv1.1", "TLSv1.2"]
   }
}
 enabled = true
 
default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-mytasklnct"
   
 forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

      
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
}
restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
viewer_certificate {
    cloudfront_default_certificate = true
  }

}
 
output "myo"{
 value = aws_s3_bucket_object.object
}
output "myout1"{
  value=aws_cloudfront_distribution.s3_distribution
}
