provider "aws" {
    region = var.region
}

terraform {
  backend "s3" {
    bucket = "devtsbk"
    key    = "tfproject/ec2"
    region = "eu-west-1"
  }
}

module "assignment5_vpc"  {

source = "../modules/vpc"
region = "us-east-1"
vpc_cidr = "172.32.0.0/16"
instance_tenancy = "default"
project = "devts"
vpc_pub_cidr_1a = "172.32.1.0/24"
pub_sub_availability_zone_1a="us-east-1a"
vpc_pub_cidr_1b = "172.32.2.0/24"
pub_sub_availability_zone_1b="us-east-1b"
vpc_pvt_cidr_1a = "172.32.3.0/24"
pvt_sub_availability_zone_1a="us-east-1a"
vpc_pvt_cidr_1b = "172.32.4.0/24"
pvt_sub_availability_zone_1b="us-east-1b"

}


module "assignment5_route53"  {

source = "../modules/route53"
region = "us-east-1"
hosted_zone="xyz.com"
hz_record="www.xyz.com"

}

module "assignment5_s3"  {

source = "../modules/s3"
region = "us-east-1"
project = "devts"
bucket_name="devtsbkt2241"
s3_acl="private"
key_name="index.html"
source_path="C:\\Software\\Data\\Important\\Devops\\Valaxy_AWS\\terraform-code\\modules\\s3\\index.html"

}

module "assignment5_iamrole"  {

source = "../modules/iamrole"
region = "us-east-1"
role_name="SSM-S3-role2-EC2"
EC2_to_SSM="AmazonEC2RoleforSSM"
EC2_to_S3="AmazonS3FullAccess"
}


resource "aws_security_group" "devts_allow_ssh_http" {
  name        = "devts_allow_ssh_http"
  description = "allow 80 & 22 ports"
  vpc_id      = module.assignment5_vpc.vpc_id

  ingress {
    description      = "ssh to ec2"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }


 tags = {
    Name = var.project
  }
}

resource "aws_instance" "devts_priv_instace1a" {
  ami           = "ami-0ab4d1e9cf9a1215a"
  instance_type = var.instance_type
  iam_instance_profile=module.assignment5_iamrole.ec2_profile_name
  user_data="${file("user_data.sh")}"
  subnet_id = module.assignment5_vpc.devts_pvt_subnet_1a
  key_name = var.key

  tags = {
    Name = var.project
  }
}

resource "aws_instance" "devts_priv_instace1b" {
  ami           = "ami-0ab4d1e9cf9a1215a"
  instance_type = var.instance_type
  iam_instance_profile=module.assignment5_iamrole.ec2_profile_name
  user_data="${file("user_data.sh")}"
  subnet_id = module.assignment5_vpc.devts_pvt_subnet_1b
  key_name = var.key

  tags = {
    Name = var.project
  }
}

resource "aws_network_interface_sg_attachment" "sg_attachment_instace1a" {
  security_group_id    = aws_security_group.devts_allow_ssh_http.id
  network_interface_id = aws_instance.devts_priv_instace1a.primary_network_interface_id
}

resource "aws_network_interface_sg_attachment" "sg_attachment_instace1b" {
  security_group_id    = aws_security_group.devts_allow_ssh_http.id
  network_interface_id = aws_instance.devts_priv_instace1b.primary_network_interface_id
}


resource "aws_lb_target_group" "devts_tg" {
  name     = "devts-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = module.assignment5_vpc.vpc_id

  health_check {
    path = "/index.html"
    port = 80
    protocol = "HTTP"
    healthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "devts_tg_instace1a" {
  target_group_arn = aws_lb_target_group.devts_tg.arn
  target_id        = aws_instance.devts_priv_instace1a.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "devts_tg_instace1b" {
  target_group_arn = aws_lb_target_group.devts_tg.arn
  target_id        = aws_instance.devts_priv_instace1b.id
  port             = 80
}

resource "aws_lb" "devts_nlb" {
  name               = "devts-nlb"
  internal           = false
  load_balancer_type = "network"
  subnet_mapping {
    subnet_id     = module.assignment5_vpc.devts_pub_subnet_1a
  }
  subnet_mapping {
    subnet_id     = module.assignment5_vpc.devts_pub_subnet_1b

  }
  enable_cross_zone_load_balancing = true
  tags = {
    Name = var.project
  }
}

resource "aws_lb_listener" "devts_nlb_listner" {
  load_balancer_arn = aws_lb.devts_nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.devts_tg.arn
  }
}

resource "aws_route53_record" "www_simple_routing_nlb" {
  zone_id = module.assignment5_route53.devts_hosted_zone_id
  name    = var.hz_record
  type    = "A"
  alias {
    name                   = aws_lb.devts_nlb.dns_name
    zone_id                = aws_lb.devts_nlb.zone_id
    evaluate_target_health = true
  }
}