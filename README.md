# MSP Demo Client Infrastructure

*Godspoon | dev@spoon.rip*

A practical demonstration of how modern MSPs can manage client infrastructure using **OpenTofu**, **GitHub**, and **Scalr** on Google Cloud Platform. This setup leverages GCP's generous Always Free tier, so your demo environments can run at zero cost.

## Why This Matters

### For MSPs:
- **Version Control Everything**: No more "who changed what when" mysteries
- **Scale Efficiently**: Manage multiple clients with consistent patterns
- **Reduce Emergency Calls**: Automated deployments and proper monitoring
- **Professional Appearance**: Clients see their infrastructure managed as code
- **Cost Control**: Free tier for demos, predictable scaling for production

### For Clients:
- **Transparency**: Complete visibility into infrastructure changes
- **Reliability**: Consistent, tested deployment patterns
- **Cost-Effective**: Start free, scale up as needed
- **Growth Ready**: Infrastructure that scales with their business
- **Documentation**: Everything is tracked and documented

## Architecture Overview

```
┌───────────────────┐    ┌───────────────────┐    ┌───────────────────┐
│                   │    │                   │    │                   │
│    GitHub Repo    │──▶│       Scalr       │──▶│   GCP Project     │
│                   │    │                   │    │                   │
│  - Infrastructure │    │  - State mgmt     │    │ - Compute Engine  │
│  - Change history │    │  - Policy enforce │    │ - Cloud Storage   │
│  - Team reviews   │    │  - Cost tracking  │    │ - VPC Network     │
│                   │    │  - Automation     │    │ - Monitoring      │
└───────────────────┘    └───────────────────┘    └───────────────────┘
```

## What Gets Built

This infrastructure creates a complete web application environment:

**Core Resources:**
- **VPC Network** with custom subnet
- **Compute Engine Instance** (f1-micro for free tier)
- **Static IP Address** for consistent access
- **Cloud Storage Bucket** for backups and files
- **Firewall Rules** for HTTP and SSH access
- **Service Account** with appropriate IAM permissions
- **Cloud Logging** for monitoring and troubleshooting

**Cost Breakdown:**
- **Dev Environment**: $0/month (Always Free tier)
- **Staging**: ~$15/month (small production instance)
- **Production**: ~$35-50/month (production-ready setup)

## Project Structure

```
demo-client-infrastructure/
├── main.tf                     # Core infrastructure resources
├── variables.tf                # Configuration options
├── outputs.tf                  # Important values and commands
├── terraform.tf                # Provider configuration
├── environments/               # Environment-specific settings
│   ├── dev/terraform.tfvars   # Free tier configuration
│   ├── staging/terraform.tfvars
│   └── prod/terraform.tfvars
└── README.md                   # This file
```

## Getting Started

### Prerequisites

**Install Google Cloud CLI (Arch Linux):**
```bash
# Install from AUR
yay -S google-cloud-cli

# Alternative: Install from official package
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
tar -xf google-cloud-cli-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh
```

**Initialize and Login:**
```bash
# Initialize gcloud
gcloud init

# Login to your Google account
gcloud auth login

# Set default project (replace with your project ID)
gcloud config set project YOUR_PROJECT_ID

# Enable application default credentials for Terraform
gcloud auth application-default login
```

### GCP Project Setup

**Enable Required APIs:**
```bash
gcloud services enable compute.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable logging.googleapis.com
```

**Create Service Account for Scalr:**
```bash
gcloud iam service-accounts create scalr-terraform \
    --display-name="Scalr Terraform Service Account"
```

**Grant Necessary Permissions:**
```bash
# Replace PROJECT_ID with your actual project ID
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:scalr-terraform@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.admin"

gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:scalr-terraform@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:scalr-terraform@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/logging.admin"
```

**Create Service Account Key:**
```bash
gcloud iam service-accounts keys create scalr-key.json \
    --iam-account=scalr-terraform@PROJECT_ID.iam.gserviceaccount.com
```

### Repository Setup

1. **Clone this repository**
2. **Update `environments/dev/terraform.tfvars`** with your project ID
3. **Configure Scalr workspace** with the service account key
4. **Set sensitive variables** in Scalr:
   - `ssh_public_key`: Your SSH public key
   - `msp_ip_range`: Your office IP range (for SSH access)
5. **Push changes** and watch Scalr deploy your infrastructure

## Environment Configuration

### Development (Free Tier)
- **Machine Type**: f1-micro (free)
- **Disk**: 10GB persistent disk
- **Storage**: 5GB Cloud Storage
- **Cost**: $0/month

### Staging 
- **Machine Type**: e2-small
- **Disk**: 20GB persistent disk
- **Cost**: ~$15/month

### Production
- **Machine Type**: n1-standard-1
- **Disk**: 50GB persistent disk
- **Enhanced monitoring and backup**
- **Cost**: ~$35-50/month

## Security Considerations

- **Network Isolation**: VPC with custom subnets
- **Firewall Rules**: Minimal required access (HTTP, SSH from your IP)
- **Service Accounts**: Least privilege access
- **Secret Management**: Sensitive data stored in Scalr, not Git
- **Audit Trail**: Complete change history in Git and Scalr

## Free Tier Limits

**Always Free Resources:**
- 1 f1-micro Compute Engine instance (US regions only)
- 30GB persistent disk storage
- 5GB Cloud Storage (regional)
- 1GB network egress per month
- Static IP (when attached to running instance)

**Supported Regions for Free Tier:**
- us-central1 (Iowa)
- us-east1 (South Carolina)  
- us-west1 (Oregon)

## Scaling to Multiple Clients

Each client gets their own GCP project, providing:
- **Isolated billing** and resource quotas
- **Independent free tier** allowances
- **Clear security boundaries**
- **Simplified management** through consistent patterns

The same Terraform code works across all environments - just different variable values and project targets.

## Common Operations

**SSH to instance:**
```bash
ssh ubuntu@INSTANCE_IP
```

**Upload files to storage:**
```bash
gsutil cp myfile.txt gs://BUCKET_NAME/
```

**View logs:**
```bash
gcloud logging read 'resource.type="gce_instance"' --limit=10
```

**Check costs:**
```bash
gcloud billing budgets list
```

## Troubleshooting

**Instance won't start?** Check if you're in a free tier region and haven't exceeded the f1-micro limit.

**Permission denied?** Verify the service account has the required IAM roles.

**API errors?** Ensure all required APIs are enabled in your project.

**High costs?** Make sure you're using f1-micro instances and staying within free tier limits.

## Support

This infrastructure pattern scales from free demos to enterprise production. Once you've got the basics working, it's easy to spoon-feed additional clients into the same proven workflow.

Questions? Reach out at **dev@spoon.rip** 

---

*Built with Infrastructure as Code by godspoon*
