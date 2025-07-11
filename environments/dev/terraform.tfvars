# Development Environment Configuration
# This configuration uses Google Cloud's Always Free tier

client_name    = "demo-client"
environment    = "dev"

# Google Cloud Configuration
gcp_project_id = "opentf"  # Replace with your actual GCP project ID
gcp_region     = "us-central1"            # Free tier region

# Compute Configuration (Free Tier)
machine_type   = "f1-micro"               # Free: 1 f1-micro instance per month
disk_size_gb   = 10                       # Free: Up to 30GB persistent disk
preemptible    = false                    # Don't use preemptible for demo stability

# Storage Configurationca
storage_class  = "STANDARD"               # Free: 5GB regional storage

# Network Configuration
subnet_cidr         = "10.0.1.0/24"
allow_http_traffic  = true
allow_https_traffic = true

# Security Configuration
# NOTE: ssh_public_key and msp_ip_range should be set in Scalr as sensitive variables
# msp_ip_range = "203.0.113.0/24"  # Replace with your actual office IP range

# Monitoring and Logging
enable_monitoring = true                   # Free: 50GB Cloud Logging per month

# Additional Labels for Organization
additional_labels = {
  cost_center = "development"
  team        = "infrastructure"
  purpose     = "demo"
  tier        = "free"
}
