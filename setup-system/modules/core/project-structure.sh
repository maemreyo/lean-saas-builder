#!/bin/bash
# modules/core/project-structure.sh
# Module: Project Structure Setup
# Version: 2.0.0
# Description: Creates basic project directory structure
# Depends: none
# Author: SaaS Template Team

set -e

# Module configuration
MODULE_NAME="project-structure"
MODULE_VERSION="2.0.0"
PROJECT_NAME=${1:-"lean-saas-app"}

# Import shared utilities if available
if [[ -f "$(dirname "$0")/../../lib/logger.sh" ]]; then
    source "$(dirname "$0")/../../lib/logger.sh"
else
    # Fallback logging functions
    log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
    log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
    log_warning() { echo -e "\033[1;33m⚠️  $1\033[0m"; }
    log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
    log_step() { echo -e "\033[0;35m🚀 $1\033[0m"; }
fi

# ==============================================================================
# MODULE FUNCTIONS
# ==============================================================================

setup_project_structure() {
    log_info "Creating project structure for $PROJECT_NAME..."

    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"

    # Main directories (don't create frontend subdirectories yet)
    mkdir -p supabase shared docs .vscode scripts

    # Supabase subdirectories
    mkdir -p supabase/functions supabase/migrations supabase/seed supabase/policies
    mkdir -p supabase/functions/stripe-webhook supabase/functions/send-email supabase/functions/user-management

    # Shared subdirectories
    mkdir -p shared/types shared/utils shared/constants shared/schemas

    log_success "Project structure created"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_step "Starting project-structure"
    setup_project_structure
    log_success "project-structure completed!"
}

# Error handling
trap 'log_error "Module failed at line $LINENO"' ERR

# Execute main function
main "$@"
