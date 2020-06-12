provider "aws"{
	region ="ap-south-1"
	profile="gopalprofile"
	}



//creating security_group
resource "aws_security_group" "mytask" {
  name        = "mytask"
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
    Name = "mytask"
  }
}


//aws instance create
resource "aws_instance" "mytaskinst" {
	ami="ami-07a8c73a650069cf3"
	instance_type="t2.micro"
	key_name="mytaskkey"
	security_groups=["mytask"]
	
	tags =  {
	  Name="mytaskos1"
	}
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/gopal/Desktop/mytaskkey.pem")
    host     = aws_instance.mytaskinst.public_ip
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
resource "aws_ebs_volume" "esb2" {
  availability_zone = aws_instance.mytaskinst.availability_zone
  size              = 1

  tags = {
    Name = "mytaskebs"
  }
}

//attaching volume to instance

resource "aws_volume_attachment" "ebs_att" {
  depends_on=[aws_ebs_volume.esb2,aws_instance.mytaskinst]
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.esb2.id
  instance_id = aws_instance.mytaskinst.id
  force_detach = true
}

resource "null_resource" "nullremote"  {

depends_on = [
    aws_volume_attachment.ebs_att,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/gopal/Desktop/mytaskkey.pem")
    host     = aws_instance.mytaskinst.public_ip
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

resource "null_resource" "nulllocal1"  {

depends_on = [
    null_resource.nullremote,
  ]

	provisioner "local-exec" {
	    command = "start  http://${aws_instance.mytaskinst.public_ip}"
  	}
}

output "myo"{
 value = aws_instance.mytaskinst.public_ip
}

