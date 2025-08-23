output "alb_arn" {
 value = aws_lb.main.arn
}

output "alb_dns_name" {
 value = aws_lb.main.dns_name
}

output "alb_zone_id" {
 value = aws_lb.main.zone_id
}

output "blue_target_group_arn" {
 value = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
 value = aws_lb_target_group.green.arn
}

output "https_listener_arn" {
 value = aws_lb_listener.https.arn
}
