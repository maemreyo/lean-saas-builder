#!/bin/bash
# modules/core/frontend-setup.sh
# Module: Frontend Setup
# Version: 2.0.0
# Description: Sets up Next.js frontend with dependencies
# Depends: none
# Author: SaaS Template Team

set -e

# Module configuration
MODULE_NAME="frontend-setup"
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

#!/bin/bash
# Module 2: Frontend Setup (Next.js + Dependencies) - FIXED

log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }

setup_frontend() {
    log_info "Setting up Next.js frontend..."
    
    # Create frontend directory if it doesn't exist
    mkdir -p frontend
    cd frontend
    
    # Check if pnpm is installed
    if ! command -v pnpm &> /dev/null; then
        log_info "Installing pnpm..."
        npm install -g pnpm
    fi
    
    # Check if directory has files, if so clear it first
    if [ "$(ls -A .)" ]; then
        log_info "Clearing existing frontend files..."
        rm -rf ./* .* 2>/dev/null || true
    fi
    
    # Initialize Next.js project
    pnpm create next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --skip-install
    
    # Add SaaS-specific dependencies
    log_info "Adding SaaS dependencies..."
    
    # Core dependencies
    pnpm add @supabase/ssr @supabase/supabase-js
    pnpm add @stripe/stripe-js stripe
    pnpm add resend @react-email/components @react-email/render
    
    # UI Components (only valid Radix UI packages)
    pnpm add @radix-ui/react-dialog @radix-ui/react-dropdown-menu
    pnpm add @radix-ui/react-select @radix-ui/react-toast
    pnpm add @radix-ui/react-accordion @radix-ui/react-tabs
    pnpm add @radix-ui/react-avatar
    pnpm add lucide-react
    
    # Utilities
    pnpm add class-variance-authority clsx tailwind-merge
    pnpm add zod react-hook-form @hookform/resolvers
    pnpm add date-fns
    pnpm add next-themes
    pnpm add sonner # Better toast notifications
    
    # State Management
    pnpm add zustand
    
    # Development dependencies
    pnpm add -D @types/node prettier prettier-plugin-tailwindcss
    pnpm add -D @types/react @types/react-dom
    pnpm add -D tailwindcss-animate
    
    # Install all dependencies
    pnpm install
    
    cd ..
    log_success "Frontend setup completed"
}

setup_frontend

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_step "Starting frontend-setup"
    setup_frontend-setup
    log_success "frontend-setup completed!"
}

# Error handling
trap 'log_error "Module failed at line $LINENO"' ERR

# Execute main function
main "$@"
