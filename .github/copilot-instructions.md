# Copilot Instructions for myTerraformProject

## Project Overview
This is a learning Terraform project for AWS Infrastructure-as-Code (IaC) development. The project demonstrates basic AWS S3 resource management with Terraform best practices.

## Architecture & Key Components

### Project Structure
- **terraform.tf**: Provider configuration and Terraform version constraints
  - AWS provider (v~> 5.92) in us-west-2 region
  - Terraform version requirement: >= 1.2
- **variables.tf**: Input variable definitions
  - `bucket_name` (string): Global S3 bucket identifier
- **dev.auto.tfvars**: Development environment variable values
  - Automatically loaded by Terraform; bucket name must be globally unique
- **main.tf**: Core AWS resources (currently minimal)
  - `aws_s3_bucket`: Main S3 bucket resource
  - `aws_s3_object`: File upload to bucket (using docs/passion.pdf)
- **docs/**: Documentation and assets directory

### Key Patterns
1. **Variable-driven configuration**: All mutable values (bucket_name) defined in variables.tf and set via *.auto.tfvars
2. **Minimal state**: This is an educational project with basic resource definitions
3. **File references**: Source files (docs/passion.pdf) are relative to the project root

## Critical Workflows

### Common Terraform Commands
```bash
# Validate syntax without backend/state
terraform validate

# Preview resource changes
terraform plan

# Apply configuration
terraform apply

# View current state
terraform state list

# Destroy all resources
terraform destroy
```

### Development Process
1. Modify variables.tf or main.tf
2. Run `terraform validate` to check syntax
3. Run `terraform plan` to preview changes
4. Run `terraform apply` to deploy to AWS

### State Management
- State files are **not** committed to version control (should be in .gitignore)
- Development state stored locally during learning
- S3 backend recommended for team environments

## Project-Specific Conventions

1. **Bucket Naming**: S3 bucket names are globally unique across AWS. The `bucket_name` variable must be unique or terraform apply will fail.
2. **Resource Tagging**: Standard tags applied to resources (Name, Environment)
3. **File Paths**: Source files reference relative paths (e.g., "docs/passion.pdf")
4. **Variable Defaults**: Variables have empty string defaults; actual values in *.auto.tfvars

## Integration Points

### AWS Service Dependencies
- AWS account credentials required (configured via AWS CLI or environment variables)
- IAM permissions needed: S3 bucket creation, object upload
- No backend state infrastructure (local state)

### External Dependencies
- **docs/passion.pdf**: File required for S3 object upload; path must exist

## Common AI Agent Tasks

When extending this project:
- **Adding resources**: Define in main.tf, add inputs to variables.tf
- **Modifying bucket settings**: Use aws_s3_bucket_* resources for non-destructive updates (versioning, encryption, etc.)
- **Handling state conflicts**: Always `terraform plan` before apply to review changes
- **Testing**: Use `terraform validate` and `terraform plan` extensively

## Documentation
- README.md contains project purpose
- Inline comments should explain non-obvious AWS configuration
