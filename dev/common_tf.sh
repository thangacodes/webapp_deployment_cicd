#!/bin/bash

# Ansi color code variables
GREEN="\033[1;32m"
RED="\033[1;31m"
RESET="\033[0m"
# heading of the script
printf "${GREEN} tf init script started %s${RESET}\n" "$(date '+%Y-%m-%d %H:%M:%S')"
# Step 1: Terraform Format
printf "${GREEN}Running: terraform fmt...${RESET}\n"
terraform fmt
if [ $? -eq 0 ]; then
    printf "${GREEN}Syntax formatting completed successfully.${RESET}\n"
else
    printf "${RED}Syntax formatting failed. Exiting.${RESET}\n"
    exit 1
fi
# Step 2: Terraform Validate
printf "${GREEN}Running: terraform validate...${RESET}\n"
terraform validate
if [ $? -eq 0 ]; then
    printf "${GREEN}Terraform configuration is valid.${RESET}\n"
else
    printf "${RED}Terraform validation failed. Exiting.${RESET}\n"
    exit 1
fi
# Step 3: Terraform Plan
printf "${GREEN}Running: terraform plan...${RESET}\n"
terraform plan
if [ $? -ne 0 ]; then
    printf "${RED}Terraform plan failed. Exiting.${RESET}\n"
    exit 1
fi
