#!/bin/bash
set -e

echo "==================================="
echo "Destroy Infrastructure"
echo "==================================="

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}WARNING: This will destroy all infrastructure!${NC}"
read -p "Are you sure? (type 'yes' to confirm): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

read -sp "Enter database password: " DB_PASSWORD
echo

cd infrastructure
terraform destroy -var="db_password=$DB_PASSWORD" -auto-approve

echo -e "${YELLOW}Infrastructure destroyed.${NC}"
