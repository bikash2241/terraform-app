#!/bin/bash
yum install httpd -y
yum -y install java-1.8*
aws s3 cp s3://devtsbkt2241/index.html /var/www/html/
service httpd start