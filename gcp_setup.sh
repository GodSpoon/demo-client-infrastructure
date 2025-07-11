#!/bin/bash

# Everforest Dark Hard color palette (ANSI escape codes)
FG='#D3C6AA'
BG='#272E33'

BLACK='\033[38;2;46;56;60m'
RED='\033[38;2;230;126;128m'
GREEN='\033[38;2;167;192;128m'
YELLOW='\033[38;2;219;188;127m'
BLUE='\033[38;2;127;187;179m'
MAGENTA='\033[38;2;214;153;182m'
CYAN='\033[38;2;131;192;146m'
WHITE='\033[38;2;211;198;170m'

BRIGHT_BLACK='\033[38;2;92;106;114m'
BRIGHT_RED='\033[38;2;248;85;82m'
BRIGHT_GREEN='\033[38;2;141;161;1m'
BRIGHT_YELLOW='\033[38;2;223;160;0m'
BRIGHT_BLUE='\033[38;2;58;148;197m'
BRIGHT_MAGENTA='\033[38;2;223;105;186m'
BRIGHT_CYAN='\033[38;2;53;167;124m'
BRIGHT_WHITE='\033[38;2;223;221;200m'

RESET='\033[0m'

# Pretty print functions
print_header() { echo -e "${BRIGHT_BLUE}$1${RESET}"; }
print_prompt() { echo -en "${CYAN}$1${RESET}"; }
print_success() { echo -e "${BRIGHT_GREEN}$1${RESET}"; }
print_warning() { echo -e "${YELLOW}$1${RESET}"; }
print_error() { echo -e "${BRIGHT_RED}$1${RESET}"; }
print_info() { echo -e "${WHITE}$1${RESET}"; }

# Error handling function
check_status() {
  if [ $? -ne 0 ]; then
    print_error "ERROR: $1 failed. Exiting."
    exit 1
  fi
}

# Function to check if project exists and user has access
check_project_access() {
  gcloud projects describe "$1" &>/dev/null
  return $?
}

# Function to wait for IAM propagation
wait_for_iam_propagation() {
  print_info "Waiting for IAM changes to propagate..."
  sleep 15
}

# 1. Prompt for project name with default 'opentf'
print_header "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_header "   Google Cloud CLI Project Setup (Everforest)   "
print_header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

print_prompt "Enter your Google Cloud project name [${BRIGHT_YELLOW}opentf${CYAN}]: "
read input_project
PROJECT_ID=${input_project:-opentf}
print_info "\nUsing project: ${BRIGHT_YELLOW}$PROJECT_ID${WHITE}\n"

# 2. Check if gcloud CLI is installed; if not, install via curl
if ! command -v gcloud &>/dev/null; then
  print_warning "gcloud CLI not found. Installing via curl...\n"
  curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
  check_status "gcloud download"
  tar -xf google-cloud-cli-linux-x86_64.tar.gz
  check_status "gcloud extraction"
  ./google-cloud-sdk/install.sh --quiet
  check_status "gcloud installation"
  export PATH="$PWD/google-cloud-sdk/bin:$PATH"
  echo 'export PATH="$HOME/google-cloud-sdk/bin:$PATH"' >>~/.bashrc
  print_success "gcloud CLI installed.\n"
else
  print_success "gcloud CLI is already installed.\n"
fi

# 3. Authentication and project setup
print_header "Checking authentication status..."
CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)

if [ -z "$CURRENT_ACCOUNT" ]; then
  print_warning "No active account found. Please authenticate..."
  gcloud auth login
  check_status "gcloud authentication"
else
  print_success "Already authenticated as: ${BRIGHT_YELLOW}$CURRENT_ACCOUNT${BRIGHT_GREEN}"
  print_prompt "Do you want to use this account? [${BRIGHT_YELLOW}Y${CYAN}/n]: "
  read USE_CURRENT
  if [[ "$USE_CURRENT" =~ ^[Nn]$ ]]; then
    gcloud auth login
    check_status "gcloud authentication"
  fi
fi

# Check if project exists, create if needed
print_header "Checking project access..."
if check_project_access "$PROJECT_ID"; then
  print_success "Project ${BRIGHT_YELLOW}$PROJECT_ID${BRIGHT_GREEN} exists and you have access."
else
  print_warning "Project ${BRIGHT_YELLOW}$PROJECT_ID${YELLOW} not found or no access. Creating..."
  gcloud projects create "$PROJECT_ID"
  check_status "project creation"
  print_info "Waiting for project to be ready..."
  sleep 10
fi

print_header "Setting active project to ${BRIGHT_YELLOW}$PROJECT_ID${BRIGHT_BLUE}..."
gcloud config set project "$PROJECT_ID"
check_status "setting project"

print_header "Setting up application default credentials..."
gcloud auth application-default login
check_status "application default login"
gcloud auth application-default set-quota-project "$PROJECT_ID"
check_status "setting quota project"

# 4. Billing setup
print_header "\nBilling Setup"
print_info "Checking if billing is already enabled..."
BILLING_ENABLED=$(gcloud billing projects describe "$PROJECT_ID" --format="value(billingEnabled)" 2>/dev/null)

if [ "$BILLING_ENABLED" = "True" ]; then
  print_success "Billing is already enabled for project ${BRIGHT_YELLOW}$PROJECT_ID${BRIGHT_GREEN}"
else
  print_info "Listing available billing accounts:\n"
  gcloud billing accounts list

  if [ $? -ne 0 ]; then
    print_error "Cannot list billing accounts. Make sure you have billing admin permissions."
    exit 1
  fi

  print_prompt "\nEnter your Billing Account ID (e.g., 0X0X0X-0X0X0X-0X0X0X): "
  read BILLING_ACCOUNT_ID

  if [ -z "$BILLING_ACCOUNT_ID" ]; then
    print_error "Billing Account ID cannot be empty"
    exit 1
  fi

  print_header "Linking billing account ${BRIGHT_YELLOW}$BILLING_ACCOUNT_ID${BRIGHT_BLUE} to project ${BRIGHT_YELLOW}$PROJECT_ID${BRIGHT_BLUE}..."
  gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT_ID"
  check_status "billing account linking"
fi

# 5. Enable required APIs (including all APIs needed for Terraform operations)
print_header "\nEnabling required APIs..."
REQUIRED_APIS=(
  "compute.googleapis.com"
  "storage.googleapis.com"
  "logging.googleapis.com"
  "iam.googleapis.com"
  "serviceusage.googleapis.com"
  "cloudresourcemanager.googleapis.com"
  "cloudbilling.googleapis.com"
)

for API in "${REQUIRED_APIS[@]}"; do
  print_info "Enabling ${BRIGHT_YELLOW}$API${WHITE}..."
  gcloud services enable "$API" --project="$PROJECT_ID"
  if [ $? -ne 0 ]; then
    print_warning "Failed to enable $API. Continuing..."
  else
    print_success "Successfully enabled $API"
  fi
done

# Wait for APIs to propagate
print_info "Waiting for APIs to propagate..."
sleep 15

# 6. Create Service Account for Scalr
print_header "\nSetting up Scalr Terraform service account..."
SERVICE_ACCOUNT_EMAIL="scalr-terraform@${PROJECT_ID}.iam.gserviceaccount.com"

# Check if service account already exists
gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" &>/dev/null
if [ $? -eq 0 ]; then
  print_success "Service account ${BRIGHT_YELLOW}$SERVICE_ACCOUNT_EMAIL${BRIGHT_GREEN} already exists."
  print_prompt "Do you want to recreate it? [y/${BRIGHT_YELLOW}N${CYAN}]: "
  read RECREATE
  if [[ "$RECREATE" =~ ^[Yy]$ ]]; then
    print_warning "Deleting existing service account..."
    gcloud iam service-accounts delete "$SERVICE_ACCOUNT_EMAIL" --quiet
    check_status "service account deletion"
    # Wait for deletion to propagate
    sleep 10
  else
    print_info "Using existing service account."
  fi
fi

# Create service account if it doesn't exist
gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" &>/dev/null
if [ $? -ne 0 ]; then
  print_info "Creating service account..."
  gcloud iam service-accounts create scalr-terraform \
    --display-name="Scalr Terraform Service Account" \
    --description="Service account for Scalr Terraform operations" \
    --project="$PROJECT_ID"
  check_status "service account creation"

  print_info "Waiting for service account to be ready..."
  sleep 10
fi

# 7. Grant necessary permissions to the service account
print_header "Granting roles to the service account..."

# Complete set of roles needed for the MSP infrastructure Terraform code
REQUIRED_ROLES=(
  "roles/compute.admin"                     # Create and manage compute instances
  "roles/storage.admin"                     # Create and manage storage buckets
  "roles/logging.admin"                     # Create and manage logging resources
  "roles/resourcemanager.projectIamAdmin"   # CRITICAL: Manage IAM policies (this was missing!)
  "roles/iam.serviceAccountAdmin"           # Create and manage service accounts
  "roles/iam.serviceAccountUser"            # Use service accounts
  "roles/serviceusage.serviceUsageConsumer" # Query enabled services
)

for ROLE in "${REQUIRED_ROLES[@]}"; do
  print_info "Granting ${BRIGHT_YELLOW}$ROLE${WHITE}..."
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="$ROLE"

  if [ $? -eq 0 ]; then
    print_success "Successfully granted $ROLE"
  else
    print_warning "Failed to grant $ROLE - continuing anyway"
  fi
done

# Wait for IAM changes to propagate
wait_for_iam_propagation

# 8. Create a service account key
print_header "Creating service account key..."
KEY_FILE="scalr-key.json"

# Remove existing key file if it exists
if [ -f "$KEY_FILE" ]; then
  print_warning "Removing existing key file..."
  rm "$KEY_FILE"
fi

gcloud iam service-accounts keys create "$KEY_FILE" \
  --iam-account="$SERVICE_ACCOUNT_EMAIL" \
  --project="$PROJECT_ID"
check_status "service account key creation"

# 9. Clean up any existing conflicting IAM bindings (preventing Terraform conflicts)
print_header "\nCleaning up potential Terraform conflicts..."
print_info "Checking for existing compute service accounts that might conflict..."

# Check if there are any existing demo1-dev-compute service accounts
COMPUTE_SA_EMAIL="demo1-dev-compute@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud iam service-accounts describe "$COMPUTE_SA_EMAIL" &>/dev/null
if [ $? -eq 0 ]; then
  print_warning "Found existing compute service account. Removing conflicting IAM bindings..."

  # Remove the specific bindings that Terraform wants to manage
  gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$COMPUTE_SA_EMAIL" \
    --role="roles/logging.logWriter" 2>/dev/null || true

  gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$COMPUTE_SA_EMAIL" \
    --role="roles/monitoring.metricWriter" 2>/dev/null || true

  print_success "Cleaned up conflicting IAM bindings"
fi

# 10. Verification
print_header "\nVerifying setup..."
print_info "Checking service account roles:"
gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:$SERVICE_ACCOUNT_EMAIL"

print_info "\nChecking enabled APIs:"
gcloud services list --enabled --project="$PROJECT_ID" \
  --filter="name:(compute.googleapis.com OR storage.googleapis.com OR logging.googleapis.com OR iam.googleapis.com OR serviceusage.googleapis.com)" \
  --format="table(name,title)"

# 11. Test service account permissions
print_header "\nTesting service account permissions..."
print_info "Testing if service account can create IAM bindings..."

# Create a temporary test binding to verify permissions work
TEST_RESULT=$(gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
  --role="roles/viewer" \
  --condition=None 2>&1)

if [ $? -eq 0 ]; then
  print_success "✅ Service account can manage IAM policies"
  # Clean up the test binding
  gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="roles/viewer" &>/dev/null || true
else
  print_error "❌ Service account cannot manage IAM policies"
  print_error "This will cause Terraform to fail. Check the permissions above."
fi

# 12. Success message and next steps
print_success "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "   Setup complete for project: $PROJECT_ID   "
print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

print_info "📁 Service account key saved to: ${BRIGHT_YELLOW}$KEY_FILE${WHITE}"
print_warning "🔒 IMPORTANT: Keep this key file secure and never commit it to version control!"

print_header "\nNext steps for Scalr setup:"
print_info "1. Upload the service account key (${BRIGHT_YELLOW}$KEY_FILE${WHITE}) to your Scalr workspace"
print_info "2. Configure your Scalr workspace variables:"
print_info "   - ${BRIGHT_YELLOW}gcp_project_id${WHITE}: $PROJECT_ID"
print_info "   - ${BRIGHT_YELLOW}ssh_public_key${WHITE}: Your SSH public key (mark as sensitive)"
print_info "   - ${BRIGHT_YELLOW}msp_ip_range${WHITE}: Your office IP range for SSH access"
print_info "3. Test your setup with a Terraform plan in Scalr"

print_header "\nUseful commands:"
print_info "• Get your SSH public key: ${BRIGHT_CYAN}cat ~/.ssh/id_rsa.pub${WHITE}"
print_info "• Get your public IP: ${BRIGHT_CYAN}curl ifconfig.me${WHITE}"
print_info "• View project console: ${BRIGHT_CYAN}https://console.cloud.google.com/home/dashboard?project=$PROJECT_ID${WHITE}"

print_header "\nTroubleshooting:"
print_info "• If Terraform fails with IAM errors, wait 5-10 minutes for permissions to propagate"
print_info "• For 403 errors, verify the service account key is correctly uploaded to Scalr"
print_info "• For resource conflicts, ensure no manual resources exist with the same names"

print_success "\n🥄 Ready for deployment! 🥄"

# 13. Create a quick reference file
cat >"gcp-setup-summary.txt" <<EOF
GCP Setup Summary for Project: $PROJECT_ID
Generated: $(date)

Service Account: $SERVICE_ACCOUNT_EMAIL
Key File: $KEY_FILE

Required Scalr Environment Variables:
- GCP_PROJECT_ID: $PROJECT_ID
- SSH_PUBLIC_KEY: (your SSH public key)
- MSP_IP_RANGE: (your office IP range, e.g., 203.0.113.0/24)

Console URL: https://console.cloud.google.com/home/dashboard?project=$PROJECT_ID

If you encounter issues:
1. Wait 5-10 minutes for IAM propagation
2. Verify APIs are enabled
3. Check service account key is valid in Scalr
4. Ensure no conflicting resources exist
EOF

print_info "\n📋 Setup summary saved to: ${BRIGHT_YELLOW}gcp-setup-summary.txt${WHITE}"
