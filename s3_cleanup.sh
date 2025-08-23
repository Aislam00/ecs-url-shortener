#!/bin/bash
cd terraform/envs/dev

# Remove all S3 bucket resources from Terraform state
echo "Removing S3 buckets from Terraform state..."

terraform state rm module.alb.aws_s3_bucket.alb_logs 2>/dev/null || echo "alb_logs bucket not in state"
terraform state rm module.alb.aws_s3_bucket.alb_logs_access_logs 2>/dev/null || echo "access_logs bucket not in state"
terraform state rm module.alb.aws_s3_bucket.alb_logs_replica 2>/dev/null || echo "replica bucket not in state"

# Remove all S3 configurations
terraform state rm module.alb.aws_s3_bucket_lifecycle_configuration.alb_logs 2>/dev/null || echo "lifecycle config not in state"
terraform state rm module.alb.aws_s3_bucket_lifecycle_configuration.alb_logs_access_logs 2>/dev/null || echo "access lifecycle config not in state"
terraform state rm module.alb.aws_s3_bucket_lifecycle_configuration.alb_logs_replica 2>/dev/null || echo "replica lifecycle config not in state"

terraform state rm module.alb.aws_s3_bucket_notification.alb_logs 2>/dev/null || echo "notification not in state"
terraform state rm module.alb.aws_s3_bucket_notification.alb_logs_access_logs 2>/dev/null || echo "access notification not in state"
terraform state rm module.alb.aws_s3_bucket_notification.alb_logs_replica 2>/dev/null || echo "replica notification not in state"

terraform state rm module.alb.aws_s3_bucket_policy.alb_logs 2>/dev/null || echo "policy not in state"
terraform state rm module.alb.aws_s3_bucket_public_access_block.alb_logs 2>/dev/null || echo "access block not in state"
terraform state rm module.alb.aws_s3_bucket_public_access_block.alb_logs_access_logs 2>/dev/null || echo "access block not in state"
terraform state rm module.alb.aws_s3_bucket_public_access_block.alb_logs_replica 2>/dev/null || echo "replica access block not in state"

terraform state rm module.alb.aws_s3_bucket_replication_configuration.alb_logs 2>/dev/null || echo "replication config not in state"
terraform state rm module.alb.aws_s3_bucket_replication_configuration.alb_logs_access_logs 2>/dev/null || echo "access replication not in state"

terraform state rm module.alb.aws_s3_bucket_server_side_encryption_configuration.alb_logs 2>/dev/null || echo "encryption not in state"
terraform state rm module.alb.aws_s3_bucket_server_side_encryption_configuration.alb_logs_access_logs 2>/dev/null || echo "access encryption not in state"
terraform state rm module.alb.aws_s3_bucket_server_side_encryption_configuration.alb_logs_replica 2>/dev/null || echo "replica encryption not in state"

terraform state rm module.alb.aws_s3_bucket_versioning.alb_logs 2>/dev/null || echo "versioning not in state"
terraform state rm module.alb.aws_s3_bucket_versioning.alb_logs_access_logs 2>/dev/null || echo "access versioning not in state"
terraform state rm module.alb.aws_s3_bucket_versioning.alb_logs_replica 2>/dev/null || echo "replica versioning not in state"

terraform state rm module.alb.aws_s3_bucket_logging.alb_logs 2>/dev/null || echo "logging not in state"
terraform state rm module.alb.aws_s3_bucket_logging.alb_logs_replica 2>/dev/null || echo "replica logging not in state"

echo "S3 resources removed from Terraform state"

# Check what's left
echo "Remaining resources in state:"
terraform state list | grep -E "(s3|bucket)" || echo "No S3 resources found in state"

# Apply to make sure everything is clean
echo "Applying Terraform to confirm clean state..."
terraform apply -auto-approve
