#!/bin/bash

# Script to view logs from various sources

AWS_REGION=${AWS_REGION:-us-east-1}

case "$1" in
    ecs)
        echo "Fetching ECS logs..."
        aws logs tail /ecs/python-microservice --follow --region $AWS_REGION
        ;;
    lambda)
        echo "Fetching Lambda logs..."
        aws logs tail /aws/lambda/python-microservice-audit-lambda --follow --region $AWS_REGION
        ;;
    audit)
        echo "Listing audit logs in S3..."
        BUCKET=$(aws s3 ls | grep python-microservice-logs | awk '{print $3}')
        aws s3 ls s3://$BUCKET/audit-logs/ --recursive --region $AWS_REGION
        ;;
    *)
        echo "Usage: $0 {ecs|lambda|audit}"
        echo "  ecs    - View ECS container logs"
        echo "  lambda - View Lambda function logs"
        echo "  audit  - List audit logs in S3"
        exit 1
        ;;
esac
