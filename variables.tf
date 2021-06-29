variable "region" {
    type = string
}


variable "instance_type" {
    type = string
}

variable "key" {
    type = string
}

variable "project" {
    type = string
}

variable "hz_record" {
    type = string
}

variable "vpc_cidr" { 
 type = string 
 }
variable "instance_tenancy" { 
 type = string 
 }
variable "vpc_pub_cidr_1a" { 
 type = string 
 }
variable "pub_sub_availability_zone_1a" { 
 type = string 
 }
variable "vpc_pub_cidr_1b" { 
 type = string 
 }
variable "pub_sub_availability_zone_1b" { 
 type = string 
 }
variable "vpc_pvt_cidr_1a" { 
 type = string 
 }
variable "pvt_sub_availability_zone_1a" { 
 type = string 
 }
variable "vpc_pvt_cidr_1b" { 
 type = string 
 }
variable "pvt_sub_availability_zone_1b" { 
 type = string 
 }
variable "hosted_zone" { 
 type = string 
 }
variable "bucket_name" { 
 type = string 
 }
variable "s3_acl" { 
 type = string 
 }
variable "s3_key_name" { 
 type = string 
 }
variable "source_path" { 
 type = string 
 }
variable "role_name" { 
 type = string 
 }
variable "EC2_to_SSM" { 
 type = string 
 }
variable "EC2_to_S3" { 
 type = string 
 }
variable "sg_name" { 
 type = string 
 }
variable "sg_description" { 
 type = string 
 }
variable "ec2_ami" { 
 type = string 
 }

variable "user_data" { 
 type = string 
 }
variable "tg_name" { 
 type = string 
 }
variable "tg_protocol" { 
 type = string 
 }
variable "tg_port" { 
 type = string 
 }
variable "tg_hc_path" { 
 type = string 
 }
variable "tg_hc_port" { 
 type = string 
 }
variable "tg_hc_protocol" { 
 type = string 
 }
variable "tg_hc_healthy_threshold" { 
 type = string 
 }
variable "lb_name" { 
 type = string 
 }
variable "lb_internal" { 
 type = string 
 }
variable "lb_load_balancer_type" { 
 type = string 
 }
variable "lb_listener_port" { 
 type = string 
 }
variable "lb_listener_protocol" { 
 type = string 
 }
variable "lb_default_action_type" { 
 type = string 
 }
variable "route53_record_type" { 
 type = string 
 }