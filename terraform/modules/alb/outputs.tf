output "alb_dns_name" {
 value = aws_lb.main.dns_name
}

output "alb_zone_id" {
 value = aws_lb.main.zone_id
}

output "alb_name" {
 value = aws_lb.main.name
}

output "target_group_blue_arn" {
 value = aws_lb_target_group.blue.arn
}

output "target_group_green_arn" {
 value = aws_lb_target_group.green.arn
}

output "target_group_blue_name" {
 value = aws_lb_target_group.blue.name
}

output "target_group_green_name" {
 value = aws_lb_target_group.green.name
}

output "https_listener_arn" {
 value = aws_lb_listener.https.arn
}

output "http_listener_arn" {
 value = aws_lb_listener.http_redirect.arn
}
