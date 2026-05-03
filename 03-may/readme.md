# 🏗️ Terraform Remote State Management on AWS

A production-ready setup for managing Terraform state remotely using **Amazon S3** (storage) and **Amazon DynamoDB** (state locking), configured via the AWS CLI.

---

## 📐 Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Terraform Client                  │
│              (terraform init / apply)               │
└────────────────────────┬────────────────────────────┘
                         │
          ┌──────────────┴──────────────┐
          │                             │
          ▼                             ▼
┌─────────────────┐           ┌──────────────────────┐
│   S3 Bucket     │           │   DynamoDB Table     │
│  (State Store)  │           │   (State Lock)       │
│                 │           │                      │
│ • Versioning ✓  │           │  LockID (Hash Key)   │
│ • Encryption ✓  │           │  PAY_PER_REQUEST     │
│ • Public: OFF ✓ │           │                      │
└─────────────────┘           └──────────────────────┘
```

---

## ✅ Prerequisites

| Requirement | Details |
|---|---|
| AWS CLI | v2 installed & configured (`aws configure`) |
| IAM Permissions | `AmazonS3FullAccess`, `AmazonDynamoDBFullAccess` |
| Terraform | v1.x or later |
| AWS Region | `us-east-1` (adjust as needed) |

---

## 🪣 Step 1 — Create & Configure the S3 Bucket

### 1.1 Create the Bucket
```bash
aws s3api create-bucket \
  --bucket my-terraform-state-2024 \
  --region us-east-1
```

### 1.2 Enable Versioning
Allows recovery of previous state files if corruption or accidental deletion occurs.
```bash
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-2024 \
  --versioning-configuration Status=Enabled
```

### 1.3 Block All Public Access
State files contain sensitive infrastructure data — they must never be public.
```bash
aws s3api put-public-access-block \
  --bucket my-terraform-state-2024 \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,\
     BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### 1.4 Enable Encryption at Rest (AES-256)
```bash
aws s3api put-bucket-encryption \
  --bucket my-terraform-state-2024 \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

---

## 🔒 Step 2 — Create the DynamoDB Table for State Locking

Prevents concurrent `terraform apply` runs from corrupting shared state.

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

> **Note:** The attribute `LockID` (type `String`) is required by the Terraform S3 backend — do not rename it.

---

## ✔️ Step 3 — Verify Resources in AWS Console

| Resource | Where to Check |
|---|---|
| S3 Bucket | AWS Console → S3 → Buckets → look for `my-terraform-state-2024` |
| Versioning | Bucket → Properties → Bucket Versioning → **Enabled** |
| Encryption | Bucket → Properties → Default Encryption → **SSE-S3 (AES-256)** |
| Public Access | Bucket → Permissions → Block Public Access → all **ON** |
| DynamoDB Table | AWS Console → DynamoDB → Tables → `terraform-state-lock` |

---

## 📁 Step 4 — Terraform Configuration Files

### `backend.tf` — Remote Backend Configuration

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }

  backend "s3" {
    bucket         = "my-terraform-state-2024"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}
```

### `main.tf` — Example Resource

```hcl
resource "aws_s3_bucket" "app_bucket" {
  bucket = "my-app-bucket-12345"

  tags = {
    Name        = "My App Bucket"
    Environment = "prod"
  }
}
```

---

## 🚀 Step 5 — Terraform Workflow

Run these commands in order from the directory containing your `.tf` files:

```bash
# 1. Initialize backend — downloads providers & connects to S3/DynamoDB
terraform init

# 2. Preview changes before applying
terraform plan

# 3. Auto-format code to canonical style
terraform fmt

# 4. Validate configuration syntax
terraform validate

# 5. Apply changes to infrastructure
terraform apply
```

> On first `terraform init`, Terraform will connect to your S3 backend and confirm the DynamoDB lock table. You should see:
> ```
> Successfully configured the backend "s3"!
> ```

---

## 🔑 IAM Permissions Required

Attach the following AWS-managed policies to your IAM user or role:

| Policy | Purpose |
|---|---|
| `AmazonS3FullAccess` | Read/write state files in S3 |
| `AmazonDynamoDBFullAccess` | Acquire/release state locks |

> 💡 **Tip:** For production environments, scope these down to least-privilege custom policies targeting only the specific bucket and table ARNs.

---

## 🗂️ Project Structure

```
.
├── backend.tf        # Remote backend & provider configuration
├── main.tf           # Your AWS resources
└── README.md         # This file
```

---

## 🛡️ Security Checklist

- [x] S3 bucket versioning enabled
- [x] S3 public access fully blocked
- [x] S3 server-side encryption (AES-256) enabled
- [x] DynamoDB state locking configured
- [x] State files encrypted in transit (`encrypt = true` in backend)
- [ ] (Recommended) Enable S3 access logging
- [ ] (Recommended) Use KMS customer-managed key instead of AES-256
- [ ] (Recommended) Restrict IAM to least-privilege custom policy

---

## 📚 References

- [Terraform S3 Backend Docs](https://developer.hashicorp.com/terraform/language/backend/s3)
- [AWS S3 API Reference](https://docs.aws.amazon.com/cli/latest/reference/s3api/)
- [AWS DynamoDB API Reference](https://docs.aws.amazon.com/cli/latest/reference/dynamodb/)
