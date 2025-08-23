resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.name_prefix}-alb-logs"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = 30
    }
    
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_lb" "main" {
 name               = var.name_prefix
 internal           = false
 load_balancer_type = "application"
 security_groups    = [var.alb_security_group_id]
 subnets            = var.public_subnet_ids

 enable_deletion_protection = true
 drop_invalid_header_fields = true

 access_logs {
   bucket  = aws_s3_bucket.alb_logs.bucket
   enabled = true
 }

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

resource "aws_wafv2_web_acl_association" "main" {
 resource_arn = aws_lb.main.arn
 web_acl_arn  = var.waf_web_acl_arn
}
