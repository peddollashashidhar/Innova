output "state_bucket" {
  value = aws_s3_bucket.tfstate.bucket
}

output "dynamodb_table" {
  value = aws_dynamodb_table.tf_locks.name
}

output "kms_key_arn" {
  value = aws_kms_key.tfstate_key.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_role.arn
}
