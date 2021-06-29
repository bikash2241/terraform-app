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
region = var.region
vpc_cidr = var.vpc_cidr
instance_tenancy = var.instance_tenancy
project = var.project
vpc_pub_cidr_1a = var.vpc_pub_cidr_1a
pub_sub_availability_zone_1a=var.pub_sub_availability_zone_1a
vpc_pub_cidr_1b = var.vpc_pub_cidr_1b
pub_sub_availability_zone_1b=var.pub_sub_availability_zone_1b
vpc_pvt_cidr_1a = var.vpc_pvt_cidr_1a
pvt_sub_availability_zone_1a=var.pvt_sub_availability_zone_1a
vpc_pvt_cidr_1b = var.vpc_pvt_cidr_1b
pvt_sub_availability_zone_1b=var.pvt_sub_availability_zone_1b

}


module "assignment5_route53"  {

source = "../modules/route53"
region = var.region
hosted_zone=var.hosted_zone

}

module "assignment5_s3"  {

source = "../modules/s3"
region = var.region
project = var.project
bucket_name=var.bucket_name
s3_acl=var.s3_acl
key_name=var.s3_key_name
source_path=var.source_path

}

module "assignment5_iamrole"  {

source = "../modules/iamrole"
region = var.region
role_name=var.role_name
EC2_to_SSM=var.EC2_to_SSM
EC2_to_S3=var.EC2_to_S3
}


resource "aws_security_group" "devts_allow_ssh_http" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = module.assignment5_vpc.vpc_id

  ingress {
    description      = "ssh port"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  ingress {
    description      = "http port"
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
  ami = var.ec2_ami
  instance_type = var.instance_type
  iam_instance_profile=module.assignment5_iamrole.ec2_profile_name
  user_data="${file(var.user_data)}"
  subnet_id = module.assignment5_vpc.devts_pvt_subnet_1a
  key_name = var.key

  tags = {
    Name = var.project
  }
}

resource "aws_instance" "devts_priv_instace1b" {
  ami = var.ec2_ami
  instance_type = var.instance_type
  iam_instance_profile=module.assignment5_iamrole.ec2_profile_name
  user_data="${file(var.user_data)}"
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
  name     = var.tg_name
  port     = var.tg_port
  protocol = var.tg_protocol
  vpc_id   = module.assignment5_vpc.vpc_id

  health_check {
    path = var.tg_hc_path
    port = var.tg_hc_port
    protocol = var.tg_hc_protocol
    healthy_threshold = var.tg_hc_healthy_threshold
  }
}

resource "aws_lb_target_group_attachment" "devts_tg_instace1a" {
  target_group_arn = aws_lb_target_group.devts_tg.arn
  target_id        = aws_instance.devts_priv_instace1a.id
  port             = var.tg_port
}
resource "aws_lb_target_group_attachment" "devts_tg_instace1b" {
  target_group_arn = aws_lb_target_group.devts_tg.arn
  target_id        = aws_instance.devts_priv_instace1b.id
  port             = var.tg_port
}

resource "aws_lb" "devts_nlb" {
  name               = var.lb_name
  internal           = var.lb_internal
  load_balancer_type = var.lb_load_balancer_type
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
  port              = var.lb_listener_port
  protocol          = var.lb_listener_protocol

  default_action {
    type             = var.lb_default_action_type
    target_group_arn = aws_lb_target_group.devts_tg.arn
  }
}

resource "aws_route53_record" "www_simple_routing_nlb" {
  zone_id = module.assignment5_route53.devts_hosted_zone_id
  name    = var.hz_record
  type    = var.route53_record_type
  alias {
    name                   = aws_lb.devts_nlb.dns_name
    zone_id                = aws_lb.devts_nlb.zone_id
    evaluate_target_health = true
  }
}