variable "client_name" {
  description = "Client name for resource naming and labeling"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client_name))
    error_message = "Client name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "gcp_project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "gcp_region" {
  description = "Google Cloud region (use us-central1, us-east1, or us-west1 for free tier)"
  type        = string
  default     = "us-central1"
  validation {
    condition = contains([
      "us-central1", "us-east1", "us-west1",    # Free tier regions
      "us-central2", "us-east4", "us-west2", "us-west3", "us-west4",  # Other US regions
      "europe-west1", "europe-west2", "europe-west3",  # Europe regions
      "asia-east1", "asia-northeast1", "asia-southeast1"  # Asia regions
    ], var.gcp_region)
    error_message = "Please use a valid Google Cloud region. For free tier, use us-central1, us-east1, or us-west1."
  }
}

variable "machine_type" {
  description = "Compute Engine machine type (f1-micro for free tier)"
  type        = string
  default     = "f1-micro"
  validation {
    condition = contains([
      "f1-micro", "g1-small",                    # Shared-core machines
      "e2-micro", "e2-small", "e2-medium",       # E2 series
      "n1-standard-1", "n1-standard-2",          # N1 series
      "n2-standard-2", "n2-standard-4",          # N2 series
      "c2-standard-4", "c2-standard-8"           # C2 series
    ], var.machine_type)
    error_message = "Please use a valid machine type. For free tier, use f1-micro."
  }
}

variable "ssh_public_key" {
  description = "SSH public key for Compute Engine access (OpenSSH format)"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256) [A-Za-z0-9+/]+=*( .*)?$", var.ssh_public_key))
    error_message = "SSH public key must be in valid OpenSSH format (ssh-rsa, ssh-ed25519, or ecdsa-sha2-nistp256)."
  }
}

variable "msp_ip_range" {
  description = "IP CIDR range for MSP SSH access (restrict to your office/VPN IP range)"
  type        = string
  default     = "0.0.0.0/0"  # Replace with your MSP's IP range for better security
  validation {
    condition     = can(cidrhost(var.msp_ip_range, 0))
    error_message = "MSP IP range must be a valid CIDR notation (e.g., 203.0.113.0/24)."
  }
}

variable "enable_monitoring" {
  description = "Enable Google Cloud Monitoring and Logging (recommended for production)"
  type        = bool
  default     = true
}

variable "storage_class" {
  description = "Cloud Storage class (STANDARD for free tier)"
  type        = string
  default     = "STANDARD"
  validation {
    condition = contains([
      "STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"
    ], var.storage_class)
    error_message = "Storage class must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  }
}

variable "disk_size_gb" {
  description = "Boot disk size in GB (10GB recommended for free tier, max 30GB)"
  type        = number
  default     = 10
  validation {
    condition     = var.disk_size_gb >= 10 && var.disk_size_gb <= 100
    error_message = "Disk size must be between 10GB and 100GB. For free tier, keep under 30GB."
  }
}

variable "preemptible" {
  description = "Use preemptible instances for cost savings (not recommended for production)"
  type        = bool
  default     = false
}

# Tags for resource organization
variable "additional_labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for k, v in var.additional_labels : can(regex("^[a-z]([a-z0-9_-]{0,61}[a-z0-9])?$", k))
    ])
    error_message = "Label keys must start with a letter, contain only lowercase letters, numbers, underscores, and hyphens, and be 1-63 characters long."
  }
}

# Network configuration
variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "Subnet CIDR must be a valid CIDR notation."
  }
}

variable "allow_http_traffic" {
  description = "Allow HTTP traffic from the internet"
  type        = bool
  default     = true
}

variable "allow_https_traffic" {
  description = "Allow HTTPS traffic from the internet"
  type        = bool
  default     = true
}
