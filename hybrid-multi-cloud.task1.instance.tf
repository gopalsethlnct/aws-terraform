provider "aws"{
	region ="ap-south-1"
	profile="gopalprofile"
	}
//private key create
resource "tls_private_key" "mykey11"{
	algorithm="RSA"
	}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  key_name   = "mykey11"
  public_key = tls_private_key.mykey11.public_key_openssh
}



//creating security_group
resource "aws_security_group" "mytask11" {
  name        = "mytask11"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-557e623d"

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    cidr_blocks=["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
   ingress {
    cidr_blocks=["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  tags = {
    Name = "mytask11"
  }
}


//aws instance create
resource "aws_instance" "mytaskinst11" {
        depends_on=[aws_security_group.mytask11]
	ami="ami-07a8c73a650069cf3"
	instance_type="t2.micro"
	key_name="mykey11"
	security_groups=["mytask11"]
	
	tags =  {
	  Name="mytaskos11"
	}
  connection {
    type     = "ssh"
    user     = "ec2-user"
  //private_key = file("C:/Users/gopal/Desktop/mytaskkey.pem")
    private_key =  tls_private_key.mykey11.private_key_pem
    host     = aws_instance.mytaskinst11.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }
}

//creating ebs volume
resource "aws_ebs_volume" "esb11" {
  availability_zone = aws_instance.mytaskinst11.availability_zone
  size              = 1

  tags = {
    Name = "mytaskebs"
  }
}

//attaching volume to instance

resource "aws_volume_attachment" "ebs_att11" {
  depends_on=[aws_ebs_volume.esb11,aws_instance.mytaskinst11]
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.esb11.id
  instance_id = aws_instance.mytaskinst11.id
  force_detach = true
}

resource "null_resource" "nullremote"  {

depends_on = [
    aws_volume_attachment.ebs_att11,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
  //private_key = file("C:/Users/gopal/Desktop/mytaskkey.pem")
    private_key =  tls_private_key.mykey11.private_key_pem
    host     = aws_instance.mytaskinst11.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdd",
      "sudo mount  /dev/xvdd  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/gopalsethlnct/mywebpage.git /var/www/html/"
    ]
  }
}


//aws bucket create
resource "aws_s3_bucket" "b" {
  bucket = "mytasklnct"
  acl    = "public-read"
 
 
}
//aws S3 bucket attach
resource "aws_s3_bucket_object" "object" {
  depends_on=[aws_s3_bucket.b]  
  bucket = aws_s3_bucket.b.bucket
  key    = "ironman.jpg"
  source = "C:/Users/gopal/Desktop/Iron_Man.jpg"
  acl ="public-read"
}

//cloud front
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
//opening web page
resource "null_resource" "nulllocal1"  {
depends_on = [
    null_resource.nullremote,aws_cloudfront_distribution.s3_distribution
  ]

	provisioner "local-exec" {
	    command = "start  http://${aws_instance.mytaskinst11.public_ip}"
  	}
}

resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "echo ${tls_private_key.mykey11.private_key_pem} > mykey11.pem"
  	}
}

output "myout"{
 value = aws_instance.mytaskinst11.public_ip
}

