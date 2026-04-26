# Terraform Commands Reference

Complete guide to all Terraform commands with examples and descriptions.

## Table of Contents

1. [Initialization](#initialization)
2. [Planning & Applying](#planning--applying)
3. [State Management](#state-management)
4. [Workspaces](#workspaces)
5. [Module Operations](#module-operations)
6. [Validation & Formatting](#validation--formatting)
7. [Debugging](#debugging)
8. [Cleanup](#cleanup)
9. [Advanced](#advanced)

---

## Initialization

### terraform init

Initialize a Terraform working directory.

```bash
# Basic initialization
terraform init

# Upgrade providers to latest version
terraform init -upgrade

# Reconfigure backend without prompting
terraform init -reconfigure

# Skip backend initialization
terraform init -backend=false

# Specify backend config via CLI
terraform init -backend-config="bucket=mybucket" -backend-config="key=mykey"
```

**Use when:**
- Setting up a new Terraform project
- Changing provider versions
- Modifying backend configuration

---

## Planning & Applying

### terraform plan

Show what Terraform will do before applying.

```bash
# Generate and display plan
terraform plan

# Save plan to file
terraform plan -out=plan.tfplan

# Show plan from file
terraform show plan.tfplan

# Plan for destruction
terraform plan -destroy

# Plan for specific resource
terraform plan -target=aws_s3_bucket.example

# Plan with variables
terraform plan -var="environment=prod"

# Plan with variable file
terraform plan -var-file="prod.tfvars"

# Show plan in JSON
terraform plan -json
```

**Use when:**
- Reviewing changes before applying
- Understanding resource dependencies
- Previewing destructive operations

### terraform apply

Apply the Terraform configuration.

```bash
# Apply with confirmation
terraform apply

# Apply saved plan
terraform apply plan.tfplan

# Apply without confirmation (use carefully!)
terraform apply -auto-approve

# Apply with variables
terraform apply -var="instance_count=3"

# Apply with variable file
terraform apply -var-file="prod.tfvars"

# Apply to specific resource
terraform apply -target=aws_instance.example

# Apply multiple variable files
terraform apply \
  -var-file="common.tfvars" \
  -var-file="prod.tfvars"

# Provide input via command line
terraform apply -input=false
```

**Use when:**
- Creating or updating infrastructure
- After reviewing plan output
- Ready to make changes permanent

### terraform refresh

Update state file with real infrastructure state.

```bash
# Refresh state
terraform refresh

# Refresh without prompting
terraform refresh -input=false

# Refresh specific resource
terraform refresh -target=aws_s3_bucket.example
```

---

## State Management

### terraform state

Manage Terraform state.

```bash
# List all resources in state
terraform state list

# Show specific resource details
terraform state show aws_instance.example

# Show resource in JSON
terraform state show -json aws_instance.example

# Move resource in state
terraform state mv aws_s3_bucket.old aws_s3_bucket.new

# Remove resource from state
terraform state rm aws_s3_bucket.example

# Pull state file locally
terraform state pull > terraform.tfstate

# Push local state to remote
terraform state push terraform.tfstate

# Show lock information
terraform state lock-info

# Force unlock state
terraform force-unlock LOCK_ID
```

### terraform show

Display state file details.

```bash
# Show current state
terraform show

# Show state in JSON format
terraform show -json

# Show plan file
terraform show plan.tfplan

# Show specific resource from state
terraform show -json aws_instance.example
```

### terraform import

Import existing resources into state.

```bash
# Import S3 bucket
terraform import aws_s3_bucket.example my-bucket-name

# Import EC2 instance
terraform import aws_instance.example i-1234567890abcdef0

# Import with module
terraform import module.vpc.aws_vpc.main vpc-12345678

# Import security group rule
terraform import aws_security_group_rule.example sg-123456_ingress_80_80_tcp_0.0.0.0/0
```

**Note:** Must have resource definition in code before importing.

---

## Workspaces

### terraform workspace

Manage workspaces for multiple environments.

```bash
# List all workspaces
terraform workspace list

# Create new workspace
terraform workspace new production

# Create and switch to workspace
terraform workspace new -

# Switch to workspace
terraform workspace select production

# Show current workspace
terraform workspace show

# Delete workspace
terraform workspace delete staging

# Delete with confirmation
terraform workspace delete -force staging
```

**Common workflow:**

```bash
# Create development workspace
terraform workspace new dev
terraform workspace select dev
terraform apply -var-file="dev.tfvars"

# Create production workspace
terraform workspace new prod
terraform workspace select prod
terraform apply -var-file="prod.tfvars"
```

---

## Module Operations

### terraform get

Download and update modules.

```bash
# Download modules
terraform get

# Update modules to latest version
terraform get -update

# Upgrade modules
terraform get -update=true
```

### Module referencing

```bash
# Reference module output
output "vpc_id" {
  value = module.vpc.vpc_id
}

# Use module in another module
module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id
}
```

---

## Validation & Formatting

### terraform validate

Validate configuration syntax.

```bash
# Validate current directory
terraform validate

# Validate specific directory
terraform validate ./my-terraform

# Validate in JSON format
terraform validate -json

# Validate and show JSON
terraform validate -no-color -json
```

**Use when:**
- Checking syntax before commit
- Debugging configuration errors
- Part of CI/CD pipeline

### terraform fmt

Format Terraform files.

```bash
# Format current directory
terraform fmt

# Format all files recursively
terraform fmt -recursive

# Check format without modifying
terraform fmt -check

# Check recursively without modifying
terraform fmt -recursive -check

# Show diff of changes
terraform fmt -diff

# Specific file
terraform fmt main.tf
```

**Use when:**
- Ensuring consistent code style
- Before committing code
- As part of CI/CD pipeline

---

## Debugging

### TF_LOG Environment Variables

```bash
# Set log level to DEBUG
export TF_LOG=DEBUG

# Set to TRACE for maximum verbosity
export TF_LOG=TRACE

# Other log levels
export TF_LOG=INFO
export TF_LOG=WARN
export TF_LOG=ERROR

# Save logs to file
export TF_LOG_PATH=/tmp/terraform.log

# View logs
cat /tmp/terraform.log

# Disable logging
unset TF_LOG
unset TF_LOG_PATH
```

### terraform graph

Visualize resource dependencies.

```bash
# Show dependency graph
terraform graph

# Save as SVG
terraform graph | dot -Tsvg > graph.svg

# Save as PNG
terraform graph | dot -Tpng > graph.png

# Show graph type
terraform graph -type=apply
terraform graph -type=plan
terraform graph -type=destroy

# Graph specific module
terraform graph -module=vpc
```

### Debugging commands

```bash
# Enable debugging for a command
TF_LOG=DEBUG terraform plan

# Save detailed plan output
terraform plan -out=plan.tfplan 2>&1 | tee plan.log

# Check provider version
terraform version

# Show all providers
terraform version

# Show specific provider
terraform providers
```

---

## Cleanup

### terraform destroy

Remove all managed resources.

```bash
# Interactive destruction
terraform destroy

# Destroy without confirmation (careful!)
terraform destroy -auto-approve

# Destroy specific resource
terraform destroy -target=aws_s3_bucket.example

# Destroy without confirmation (specific resource)
terraform destroy -target=aws_s3_bucket.example -auto-approve

# Destroy with variables
terraform destroy -var="environment=prod"

# Destroy with variable file
terraform destroy -var-file="prod.tfvars"
```

**Safety measures:**

```bash
# Always review plan first
terraform plan -destroy -out=destroy.plan

# Review the plan
terraform show destroy.plan

# Then execute if satisfied
terraform apply destroy.plan
```

### Removing from state

```bash
# Remove resource (not destroyed)
terraform state rm aws_s3_bucket.example

# Remove multiple resources
terraform state rm aws_s3_bucket.example aws_instance.web

# Remove all resources in module
terraform state rm 'module.vpc'
```

---

## Advanced

### terraform console

Interactive console for testing expressions.

```bash
# Start interactive console
terraform console

# In console, test expressions
> var.instance_type
> aws_instance.example.private_ip
> data.aws_availability_zones.available.names
> local.common_tags

# Exit console
exit
```

### terraform taint

Mark resource for destruction and recreation.

```bash
# Taint resource
terraform taint aws_instance.example

# Taint in module
terraform taint 'module.vpc.aws_subnet.public'

# Untaint resource
terraform untaint aws_instance.example

# Untaint in module
terraform untaint 'module.vpc.aws_subnet.public'
```

### terraform output

Display outputs.

```bash
# Show all outputs
terraform output

# Show specific output
terraform output instance_id

# Show in JSON format
terraform output -json

# Show specific output as JSON
terraform output -json instance_id

# Raw output (useful for scripting)
terraform output -raw instance_id
```

### terraform meta-arguments

Used within resources and modules.

```hcl
# count - Create multiple resources
resource "aws_instance" "example" {
  count         = var.instance_count
  instance_type = "t3.micro"
  
  tags = {
    Name = "server-${count.index + 1}"
  }
}

# for_each - Create resources from map or set
resource "aws_instance" "example" {
  for_each      = toset(["web", "api", "db"])
  instance_type = "t3.micro"
  
  tags = {
    Name = each.value
  }
}

# depends_on - Explicit dependency
resource "aws_instance" "example" {
  depends_on = [aws_s3_bucket.example]
}

# provider - Use alternate provider configuration
resource "aws_instance" "example" {
  provider = aws.us-west-2
}
```

---

## Common Workflows

### Development Workflow

```bash
# Initialize
terraform init

# Make changes to configuration
# Edit main.tf

# Validate changes
terraform validate

# Format code
terraform fmt -recursive

# Review plan
terraform plan

# Apply if satisfied
terraform apply
```

### Production Deployment

```bash
# Create plan
terraform plan -out=prod.plan -var-file="prod.tfvars"

# Save plan for review
cp prod.plan /secure/location/

# Code review step
# Review prod.plan with team

# Apply plan
terraform apply prod.plan

# Verify deployment
terraform output
```

### Multi-Environment Setup

```bash
# Development
terraform workspace new dev
terraform workspace select dev
terraform apply -var-file="dev.tfvars"

# Staging
terraform workspace new staging
terraform workspace select staging
terraform apply -var-file="staging.tfvars"

# Production
terraform workspace new prod
terraform workspace select prod
terraform apply -var-file="prod.tfvars"

# Switch between environments
terraform workspace select dev
```

### CI/CD Pipeline

```bash
# Initialize (CI/CD runs this)
terraform init -backend-config="..."

# Validate
terraform validate

# Format check
terraform fmt -recursive -check

# Security check
tflint
checkov -d .

# Plan
terraform plan -out=tfplan

# Upload plan artifact
# (Store tfplan for apply step)

# Apply (separate pipeline step)
terraform apply tfplan

# Clean up
rm tfplan
```

---

## Performance Tips

### Parallelize Operations

```bash
# Default parallelism is 10
terraform apply -parallelism=20

# Useful for large deployments
terraform destroy -parallelism=30
```

### Target Specific Resources

```bash
# Apply only to specific resources
terraform apply -target=module.vpc

# Plan only for specific resources
terraform plan -target=aws_s3_bucket.example
```

### Refresh State Selectively

```bash
# Refresh specific resource
terraform refresh -target=aws_instance.example

# Skip refresh
terraform plan -refresh=false
```

---

## Useful Aliases

Add to your `.bashrc` or `.zshrc`:

```bash
alias tf='terraform'
alias tfi='terraform init'
alias tfv='terraform validate'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfs='terraform show'
alias tfg='terraform graph'
alias tfm='terraform workspace'
```

---

## Environment Variables

```bash
# AWS
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_DEFAULT_REGION=us-east-1

# Terraform
export TF_LOG=DEBUG
export TF_LOG_PATH=/tmp/terraform.log
export TF_INPUT=false
export TF_CLI_ARGS="-var-file=prod.tfvars"

# Variables
export TF_VAR_instance_type=t3.medium
export TF_VAR_environment=prod
```

---

**Happy Terraforming! 🚀**
