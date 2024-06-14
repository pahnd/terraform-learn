output "alb_dns" {
    value = aws_lb.aws_lb.dns_name
}

output "lb_endpoint" {
    value = aws_lb.aws_lb.dns_name
}

output "lb_tg_name" {
    value = aws_lb_target_group.app_tg.name
}

output "lb_tg" {
    value = aws_lb_target_group.app_tg.arn
}