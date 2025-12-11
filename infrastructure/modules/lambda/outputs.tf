output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.audit.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.audit.arn
}
