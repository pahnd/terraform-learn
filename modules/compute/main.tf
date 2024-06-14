data "aws_ssm_parameter" "app_ami" {
    name = "word_press"
}

#Launch template for the bastion host
resource "aws_launch_template" "app_bastion" {
  name_prefix = "app_basion"
  instance_type = var.instance_type
  image_id = data.aws_ssm_parameter.app_ami.value
  vpc_security_group_ids = [var.bastion_sg]
  #user_data = 
  key_name = var.key_name

  tag = {
    Name = "app_basion"
  }
}

# Create AWS autoscaling group to use aws_lauch_template_app_bastion
resource "aws_autoscaling_group" "app_bastion" {
    name = "app_bastion"
    max_size = 1
    min_size = 1
    desired_capacity = 1
    vpc_zone_identifier = var.public_subnets

    launch_template {
      id = aws_launch_template.app_bastion.id
      version = "$Latest"
    }
}

#Launch template for the front host
resource "aws_launch_template" "app_frontend" {
  name_prefix = "app_frontend"
  instance_type = var.instance_type
  image_id = data.aws_ssm_parameter.app_ami.value
  vpc_security_group_ids = [var.frontend_app_sg]
  key_name = var.key_name
  
  user_data = filebase64("install_apache.sh")

  tag = {
    Name = "app_frontend"
  }
}


data "aws_alb_target_group" "app_tg" {
    name = var.lb_tg_name
}

# Create AWS autoscaling group to use aws_launch_template app_frontend
resource "aws_autoscaling_group" "app_frontend" {
    name = "app_frontend"
    max_size = 2
    min_size = 1
    desired_capacity = 2
    vpc_zone_identifier = var.private_subnets
    # for use with Application or Network Load Balancing
    target_group_arns = [data.aws_alb_target_group.app_tg.arn]

    launch_template {
      id = aws_launch_template.app_frontend.id
      version = "$Latest"
    }
}


#Launch template for the backend
resource "aws_launch_template" "app_backend" {
  name_prefix = "app_backend"
  instance_type = var.instance_type
  image_id = data.aws_ssm_parameter.app_ami.value
  vpc_security_group_ids = [var.app_backend_app_sg]
  key_name = var.key_name
  
  user_data = filebase64("install_node.sh")

  tag = {
    Name = "app_app_backend"
  }
}

# Create AWS autoscaling group to use aws_launch_template app_backend
resource "aws_autoscaling_group" "app_backend" {
    name = "app_app_backend"
    max_size = 2
    min_size = 1
    desired_capacity = 2
    vpc_zone_identifier = var.private_subnets

    launch_template {
      id = aws_launch_template.app_backend.id
      version = "$Latest"
    }
}
