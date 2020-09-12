provider "aws" {
   region = "ap-south-1"
   profile = "gopalprofile"
}

#Create key pair
resource "tls_private_key" "mykeytask3"{
    algorithm = "RSA"
}

#create key-pair/aws
module "key_pair" {
	source = "terraform-aws-modules/key-pair/aws"
	key_name = "mykeytask3"
	public_key = tls_private_key.mykeytask3.public_key_openssh
} 

#create VPC
resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "myvpc"
  }
}

#security group for wordpress public
resource "aws_security_group" "mywordpress" {
    depends_on=[aws_vpc.myvpc]
	name = "mywordpress"
	description = "Allow TLS inbound traffic"
	vpc_id = aws_vpc.myvpc.id
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		cidr_blocks=["0.0.0.0/0"]
		from_port = 80
		to_port = 80
		protocol = "tcp"
	}
	ingress {
		cidr_blocks=["0.0.0.0/0"]
		from_port = -1
		to_port = -1
		protocol = "icmp"
	}
	
	
	ingress {
		cidr_blocks=["0.0.0.0/0"]
		from_port = 22
		to_port = 22
		protocol = "tcp"
		}
	ingress {
		cidr_blocks=["0.0.0.0/0"]
		from_port = 0
		to_port = 0
		protocol = "-1"
	}
	tags = {
		Name = "mywordpresssg"
	}
}

#private security groupfor mysql
resource "aws_security_group" "sql" {
    depends_on=[
	    aws_subnet.pubsub, 
		aws_vpc.myvpc,
		aws_security_group.mywordpress
	]
	name = "sql"
	description = "Allow TLS inbound traffic"
	vpc_id = aws_vpc.myvpc.id

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress {
		cidr_blocks=["${aws_subnet.pubsub.cidr_block}"]
		from_port = -1
		to_port = -1
		protocol = "icmp"
	}
	ingress {
		cidr_blocks=["${aws_subnet.pubsub.cidr_block}"]
		from_port = 22
		to_port = 22
		protocol = "tcp"
	}
	ingress {
		
		from_port = 3306
		to_port = 3306
		protocol = "tcp"
		cidr_blocks=["${aws_subnet.pubsub.cidr_block}"]
	}
	tags = {
	Name = "mysqlsg"
	}
}

#public subnet for wordpress
resource "aws_subnet" "pubsub" {
  depends_on=[aws_vpc.myvpc]
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
 
  tags = {
    Name = "public"
  }
}

#private subnet for database
resource "aws_subnet" "prisub" {
   vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private"
  }
}

#internet gateway for VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id
  depends_on=[aws_vpc.myvpc]
  tags = {
    Name = "netgateway"
  }
}

#route table
resource "aws_route_table" "routetable" {
  depends_on=[aws_vpc.myvpc,aws_internet_gateway.gw]
  vpc_id = aws_vpc.myvpc.id
   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  } 
  tags = {
    Name = "myroute"
  }
}
#connecting route table to public subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.routetable.id
  depends_on=[
  aws_subnet.pubsub, 
  aws_route_table.routetable
  ]
}

#wordpress instance
resource "aws_instance" "wordpress" {
	ami= "ami-000cbce3e1b899ebd"
	instance_type= "t2.micro"
	key_name= "mykeytask3"
	vpc_security_group_ids = [aws_security_group.mywordpress.id]
	subnet_id = aws_subnet.pubsub.id
	
	tags = {
		Name= "wordpress"
	}

}

#mysql Instance
resource "aws_instance" "mysql" {
	ami= "ami-08706cb5f68222d09"
	instance_type= "t2.micro"
	key_name= "mykeytask3"
	vpc_security_group_ids = [aws_security_group.sql.id]
	subnet_id = aws_subnet.prisub.id

	tags = {
		Name= "mysql"
	}
}

output "myoutsite"{
	value = aws_instance.wordpress.public_ip
}