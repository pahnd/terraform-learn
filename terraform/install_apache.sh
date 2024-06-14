#!/bin/bash

yum -update -y
yum install httpd
systemctl start httpd
systemctl enable httpd

echo "Running apache on $(hostname -f)" > /var/www/html/index.html