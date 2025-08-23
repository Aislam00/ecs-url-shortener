resource "aws_lb" "main" {
 name               = var.name_prefix
 internal           = false
 load_balancer_type = "application"
 security_groups    = [var.alb_security_group_id]
 subnets            = var.public_subnet_ids

 enable_deletion_protection = false
 drop_invalid_header_fields = true

 tags = var.tags
}

resource "aws_lb_target_group" "blue" {
 name        = "${var.name_prefix}-blue"
 port        = var.container_port
 protocol    = "HTTP"
 vpc_id      = var.vpc_id
 target_type = "ip"

 health_check {
   enabled             = true
   healthy_threshold   = 2
   interval            = 30
   matcher             = "200"
   path                = var.health_check_path
   port                = "traffic-port"
   protocol            = "HTTP"
   timeout             = 5
   unhealthy_threshold = 2
 }

 tags = var.tags
}

resource "aws_lb_target_group" "green" {
 name        = "${var.name_prefix}-green"
 port        = var.container_port
 protocol    = "HTTP"
 vpc_id      = var.vpc_id
 target_type = "ip"

 health_check {
   enabled             = true
   healthy_threshold   = 2
   interval            = 30
   matcher             = "200"
   path                = var.health_check_path
   port                = "traffic-port"
   protocol            = "HTTP"
   timeout             = 5
   unhealthy_threshold = 2
 }

 tags = var.tags
}

resource "aws_lb_listener" "https" {
 load_balancer_arn = aws_lb.main.arn
 port              = "443"
 protocol          = "HTTPS"
 ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
 certificate_arn   = var.certificate_arn

 default_action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.blue.arn
 }

 tags = var.tags
}

resource "aws_lb_listener" "http_redirect" {
 load_balancer_arn = aws_lb.main.arn
 port              = "80"
 protocol          = "HTTP"

 default_action {
   type = "redirect"

   redirect {
     port        = "443"
     protocol    = "HTTPS"
     status_code = "HTTP_301"
   }
 }

 tags = var.tags
}

resource "aws_wafv2_web_acl_association" "main" {
 resource_arn = aws_lb.main.arn
 web_acl_arn  = var.waf_web_acl_arn
}
