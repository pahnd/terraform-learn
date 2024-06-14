resource "aws_lb" "app_lb" {
    name = "app_lb"
    security_groups = [var.lb_sg]
    subnet = var.public_subnets
    idle_timeout = 400

    depends_on = [ var.app_sg]
}

resource "aws_lb_target_group" "app_tg" {
    name = "app_lb-tg"
    port = var.port
    protocol = var.protocol
    vpc_id = var.vpc_id
    #The lifecycle block is used to control and customize the lifecycle of resources
    lifecycle {
    # allows you to specify resource attributes that Terraform will ignore when checking for differences between the configuration and the actual state. This is helpful when certain attributes might change outside of Terraform's control and you don't want Terraform to try to update them.
        ignore_changes = [ name ]
    #Terraform creates a new resource before destroying the old one.This is particularly useful when you need to ensure that a resource is always available and avoid downtime during updates.  
        create_before_destroy = true
    }
}

#Target to aws_lb.app_lb. Connect loadbalancer with target group
resource "aws_lb_listener" "app_lb" {
    load_balancer_arn = aws_lb.app_lb.arn
    default_action {
        type = "forward"
        target_group_arn = [aws_lb_target_group.app_tg.arn]
    }
}