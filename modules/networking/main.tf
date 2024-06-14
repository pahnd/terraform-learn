resource "aws_vpc" "app_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "app_vpc"
    }
}


data "aws_availability_zones" "available" {
    state = "available"
}

#Set internet gateway run inside aws_vpc.app_vpc
resource "aws_internet_gateway" "app_internet_gateway" {
    vpc_id = aws_vpc.app_vpc.id

    tags = {
        Name = "app_ig"
    }
}


resource "aws_subnet" "app_public_subnet" {
    vpc_id = aws_vpc.app_vpc.id
    count = var.public_sn_count
    cidr_block = "10.123.${10 + count.index}.0/24"
    map_public_ip_on_lauch = true
    availability_zone = data.aws_availability_zones.available.names[count.index]

    tags = [
        Name = "app_public_subnet_${count.index + 1}"
    ]
}

# Create public route table
resource "aws_route_table" "app_public_rt" {
    vpc_id = aws_vpc.app_vpc.id

    tags = {
        Name = "app_public_rt"
    }
} 
# Bind aws_route_table to internet gateway
resource "aws_route" "app_public_subnet_rt" {
    route_table_id = aws_route_table.app_public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_internet_gateway.id
}

ressource "aws_route_table_association" "app_public_assoc" {
    route_table_id = aws_route_table.app_public_rt.id
    count = var.public_sn_count
    subnet_id = aws_subnet.app_public_subnet.id
}

#create eip
resource "aws_eip" "app_natgw_eip" {
    domain = "vpc"
}


#Create NAT Gateway
resource "aws_nat_gateway" "app_natgw" {
    allocation_id = aws_eip.app_natgw_eip.id
    subnet_id = aws_subnet.app_public_subnet.id
}


resource "aws_subnet" "app_private_subnet" {
    vpc_id = aws_vpc.app_vpc.id
    count = var.private_sn_count
    cidr_block = "10.123.${20 + count.index}.0/24"
    map_public_ip_on_lauch = false
    availability_zone = data.aws_availability_zones.available.names[count.index]

    tags = [
        Name = "app_private_subnet_${count.index + 1}"
    ]
}

resource "aws_route_table" "app_private_rt" {
    vpc_id = aws_vpc.app_vpc.id

    tags = {
        Name = "app_private_rt"
    }
}

resource "aws_route_table_association" "app_private_assoc" {
    route_table_id = aws_route_table.app_private_rt.id
    count = var.private_sn_count
    subnet_id = aws_subnet.app_private_subnet.id
}



resource "aws_subnet" "app_private_subnet" {
    vpc_id = aws_vpc.app_vpc.id
    count = var.private_sn_count
    cidr_block = "10.123.${40 + count.index}.0/24"
    map_public_ip_on_lauch = false
    availability_zone = data.aws_availability_zones.available.names[count.index]

    tags = [
        Name = "app_db_private_subnet_${count.index + 1}"
    ]
}


#SG for bastion host

resource "aws_security_group" "app_bastion_sg" {
    name = "app_sg_bastion"
    vpc_id = aws_vpc.app_vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.access_ip]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#SG for LB
resource "aws_security_group" "app_lb_sg" {
    name = "app_sg_lb"
    vpc_id = aws_vpc.app_vpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


resource "aws_security_group" "app_frontend_sg" {
    name = "app_sg_FE"
    vpc_id = aws_vpc.app_vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = [aws_security_group.app_bastion_sg.id]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.app_lb_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "app_backend_sg" {
    name = "app_sg_BE"
    vpc_id = aws_vpc.app_vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = [aws_security_group.app_bastion_sg.id]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.frontend_app_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


resource "aws_security_group" "app_db_sg" {
    name = "app_sg_DB"
    vpc_id = aws_vpc.app_vpc.id

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.app_backend_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_db_subnet_group" "app_db_subnetgroup" {
    count = var.db_subnet_group == true ? 1 : 0
    name = "db_subgroup"
    subnet_id = [aws_subnet.app_db_private_subnet[0].id, aws_subnet.app_db_private_subnet[1].id]
    tags = {
        Name = "subgroup_db"
    }
}