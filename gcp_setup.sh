#!/bin/bash

# ====== CONFIGURATION ======
PROJECT_ID="${PROJECT_ID:-opentf}"

# ====== FUNCTIONS ======

# Function to check if a command succeeded
check_status() {
  if [ $? -ne 0 ]; then
    echo "ERROR: $1 failed. Exiting."
    exit 1
  fi
}

# Function to check if project exists and user has access
check_project_access() {
  echo "Checking if project $PROJECT_ID exists and you have access..."
  gcloud projects describe "$PROJECT_ID" &>/dev/null
  return $?
}

install_gcloud() {
  if ! command -v gcloud &>/dev/null; then
    echo "gcloud CLI not found. Installing via curl..."
    curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
    check_status "gcloud download"

    tar -xf google-cloud-cli-linux-x86_64.tar.gz
    check_status "gcloud extraction"

    ./google-cloud-sdk/install.sh --quiet
    check_status "gcloud installation"

    export PATH="$PWD/google-cloud-sdk/bin:$PATH"
    echo 'export PATH="$HOME/google-cloud-sdk/bin:$PATH"' >>~/.bashrc
    echo "gcloud CLI installed."
  else
    echo "gcloud CLI is already installed."
  fi
}

authenticate_gcloud() {
  echo "=== AUTHENTICATING WITH GCLOUD ==="

  # Check if already authenticated
  CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)

  if [ -z "$CURRENT_ACCOUNT" ]; then
    echo "No active account found. Please authenticate..."
    gcloud auth login
    check_status "gcloud authentication"
  else
    echo "Already authenticated as: $CURRENT_ACCOUNT"
    read -p "Do you want to use this account? (y/n): " USE_CURRENT
    if [[ ! "$USE_CURRENT" =~ ^[Yy]$ ]]; then
      gcloud auth login
      check_status "gcloud authentication"
    fi
  fi

  # Set up application default credentials
  echo "Setting up application default credentials..."
  gcloud auth application-default login
  check_status "application default login"
}

create_or_access_project() {
  echo "=== PROJECT SETUP ==="

  if check_project_access; then
    echo "Project $PROJECT_ID exists and you have access."
    read -p "Do you want to use existing project $PROJECT_ID? (y/n): " USE_EXISTING
    if [[ ! "$USE_EXISTING" =~ ^[Yy]$ ]]; then
      read -p "Enter a different project ID: " PROJECT_ID
      if ! check_project_access; then
        echo "Project $PROJECT_ID not found or no access. Creating new project..."
        gcloud projects create "$PROJECT_ID"
        check_status "project creation"
      fi
    fi
  else
    echo "Project $PROJECT_ID does not exist or you don't have access. Creating..."
    gcloud projects create "$PROJECT_ID"
    check_status "project creation"

    # Wait a moment for project to be fully created
    echo "Waiting for project to be ready..."
    sleep 5
  fi

  # Set the current project
  gcloud config set project "$PROJECT_ID"
  check_status "setting project"

  # Set quota project for application default credentials
  gcloud auth application-default set-quota-project "$PROJECT_ID"
  check_status "setting quota project"
}

setup_billing() {
  echo "=== BILLING SETUP ==="

  # Check if billing is already enabled
  BILLING_ENABLED=$(gcloud billing projects describe "$PROJECT_ID" --format="value(billingEnabled)" 2>/dev/null)

  if [ "$BILLING_ENABLED" = "True" ]; then
    echo "Billing is already enabled for project $PROJECT_ID"
    return 0
  fi

  echo "Listing available billing accounts:"
  gcloud billing accounts list

  if [ $? -ne 0 ]; then
    echo "ERROR: Cannot list billing accounts. Make sure you have billing admin permissions."
    return 1
  fi

  echo ""
  read -p "Enter your Billing Account ID (e.g., 0X0X0X-0X0X0X-0X0X0X): " BILLING_ACCOUNT_ID

  if [ -z "$BILLING_ACCOUNT_ID" ]; then
    echo "ERROR: Billing Account ID cannot be empty"
    return 1
  fi

  echo "Linking billing account $BILLING_ACCOUNT_ID to project $PROJECT_ID..."
  gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT_ID"
  check_status "billing account linking"
}

enable_apis() {
  echo "=== ENABLING APIS ==="

  APIS=("compute.googleapis.com" "storage.googleapis.com" "logging.googleapis.com" "iam.googleapis.com")

  for API in "${APIS[@]}"; do
    echo "Enabling $API..."
    gcloud services enable "$API"
    if [ $? -ne 0 ]; then
      echo "WARNING: Failed to enable $API. Continuing..."
    else
      echo "Successfully enabled $API"
    fi
  done
}

setup_service_account() {
  echo "=== SERVICE ACCOUNT SETUP ==="

  SERVICE_ACCOUNT_EMAIL="scalr-terraform@${PROJECT_ID}.iam.gserviceaccount.com"

  # Check if service account already exists
  gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" &>/dev/null

  if [ $? -eq 0 ]; then
    echo "Service account $SERVICE_ACCOUNT_EMAIL already exists."
    read -p "Do you want to recreate it? (y/n): " RECREATE
    if [[ "$RECREATE" =~ ^[Yy]$ ]]; then
      echo "Deleting existing service account..."
      gcloud iam service-accounts delete "$SERVICE_ACCOUNT_EMAIL" --quiet
      check_status "service account deletion"
    else
      echo "Using existing service account."
      setup_iam_roles
      create_service_account_key
      return 0
    fi
  fi

  echo "Creating service account for Scalr..."
  gcloud iam service-accounts create scalr-terraform \
    --display-name="Scalr Terraform Service Account" \
    --description="Service account for Scalr Terraform operations"
  check_status "service account creation"

  # Wait a moment for service account to be ready
  echo "Waiting for service account to be ready..."
  sleep 5

  setup_iam_roles
  create_service_account_key
}

setup_iam_roles() {
  echo "Granting IAM roles to service account..."

  SERVICE_ACCOUNT_EMAIL="scalr-terraform@${PROJECT_ID}.iam.gserviceaccount.com"
  ROLES=("roles/compute.admin" "roles/storage.admin" "roles/logging.admin")

  for ROLE in "${ROLES[@]}"; do
    echo "Granting $ROLE..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
      --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
      --role="$ROLE"

    if [ $? -eq 0 ]; then
      echo "Successfully granted $ROLE"
    else
      echo "WARNING: Failed to grant $ROLE"
    fi
  done
}

create_service_account_key() {
  echo "Creating service account key..."

  SERVICE_ACCOUNT_EMAIL="scalr-terraform@${PROJECT_ID}.iam.gserviceaccount.com"
  KEY_FILE="scalr-key.json"

  # Remove existing key file if it exists
  if [ -f "$KEY_FILE" ]; then
    echo "Removing existing key file..."
    rm "$KEY_FILE"
  fi

  gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SERVICE_ACCOUNT_EMAIL"
  check_status "service account key creation"

  echo "Service account key saved to: $KEY_FILE"
  echo "IMPORTANT: Keep this key file secure and never commit it to version control!"
}

setup_project() {
  echo "=== GCP PROJECT SETUP ==="

  authenticate_gcloud
  create_or_access_project
  setup_billing
  enable_apis
  setup_service_account

  echo ""
  echo "=== Setup complete for project: $PROJECT_ID ==="
  echo "Next steps:"
  echo "1. Keep the scalr-key.json file secure"
  echo "2. Configure your Terraform/Scalr with the service account key"
  echo "3. Test your setup with a simple Terraform configuration"
}

remove_project() {
  echo "=== PROJECT REMOVAL ==="
  echo "WARNING: This will permanently delete the GCP project: $PROJECT_ID"
  echo "This action cannot be undone!"
  echo ""
  read -p "Are you sure you want to proceed? Type 'DELETE' to confirm: " CONFIRM

  if [[ "$CONFIRM" != "DELETE" ]]; then
    echo "Aborted. Project was not deleted."
    exit 1
  fi

  # Verify project exists and user has access
  if ! check_project_access; then
    echo "ERROR: Project $PROJECT_ID not found or you don't have access to it."
    exit 1
  fi

  gcloud config set project "$PROJECT_ID"
  check_status "setting project for deletion"

  echo "Deleting project $PROJECT_ID..."
  gcloud projects delete "$PROJECT_ID" --quiet
  check_status "project deletion"

  echo "Project $PROJECT_ID scheduled for deletion."
  echo "Note: It may take a few minutes for the deletion to complete."
}

# ====== MAIN SCRIPT ======

echo "GCP Project Management Script"
echo "Current project: $PROJECT_ID"
echo ""
echo "Choose an action:"
echo "  1) Setup project"
echo "  2) Remove project"
echo ""
read -p "Enter 1 or 2: " ACTION

install_gcloud

case "$ACTION" in
1)
  setup_project
  ;;
2)
  remove_project
  ;;
*)
  echo "Invalid selection. Exiting."
  exit 1
  ;;
esac
