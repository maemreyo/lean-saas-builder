#!/bin/bash
# modules/core/frontend-setup.sh - UPDATED: Added progress indicators and better UX
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

# Progress indicator function
show_progress() {
    local message="$1"
    local command="$2"
    
    log_info "$message..."
    echo "   Running: $command"
    
    # Run command with progress
    if [[ "${DEBUG:-0}" == "1" ]]; then
        # In debug mode, show full output
        eval "$command"
    else
        # In normal mode, show minimal progress
        eval "$command" 2>&1 | while IFS= read -r line; do
            # Show important lines
            if [[ "$line" =~ (Installing|Added|Downloading|Progress|✓|✗|Error|Warning) ]]; then
                echo "   $line"
            fi
        done
    fi
    
    local exit_code=${PIPESTATUS[0]}
    if [[ $exit_code -eq 0 ]]; then
        log_success "$message completed"
    else
        log_error "$message failed with exit code $exit_code"
        return $exit_code
    fi
}

# ==============================================================================
# MODULE FUNCTIONS
# ==============================================================================

setup_frontend() {
    log_step "Setting up Next.js frontend..."
    log_info "This process may take 3-5 minutes depending on your internet connection"
    echo ""
    
    # Create frontend directory if it doesn't exist
    log_info "📁 Creating frontend directory..."
    mkdir -p frontend
    cd frontend
    
    # Check if pnpm is installed
    if ! command -v pnpm &> /dev/null; then
        show_progress "🔧 Installing pnpm globally" "npm install -g pnpm"
    else
        log_success "pnpm is already installed"
    fi
    
    # Check if directory has files, if so clear it first
    if [ "$(ls -A . 2>/dev/null)" ]; then
        log_info "🧹 Clearing existing frontend files..."
        rm -rf ./* .* 2>/dev/null || true
        log_success "Directory cleared"
    fi
    
    # Initialize Next.js project
    log_step "🎯 Creating Next.js application..."
    log_info "This step typically takes 1-2 minutes..."
    show_progress "Creating Next.js app with TypeScript, Tailwind, ESLint" \
        "pnpm create next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias '@/*' --skip-install"
    
    # Add SaaS-specific dependencies in groups
    log_step "📦 Installing SaaS dependencies..."
    
    # Core dependencies
    log_info "Installing core dependencies (Supabase, Stripe, Email)..."
    show_progress "Adding Supabase packages" \
        "pnpm add @supabase/ssr @supabase/supabase-js"
    
    show_progress "Adding Stripe packages" \
        "pnpm add @stripe/stripe-js stripe"
    
    show_progress "Adding email packages" \
        "pnpm add resend @react-email/components @react-email/render"
    
    # UI Components
    log_info "Installing UI components (Radix UI, Lucide)..."
    show_progress "Adding Radix UI components" \
        "pnpm add @radix-ui/react-dialog @radix-ui/react-dropdown-menu @radix-ui/react-select @radix-ui/react-toast @radix-ui/react-accordion @radix-ui/react-tabs @radix-ui/react-avatar"
    
    show_progress "Adding Lucide React icons" \
        "pnpm add lucide-react"
    
    # Utilities
    log_info "Installing utility libraries..."
    show_progress "Adding styling utilities" \
        "pnpm add class-variance-authority clsx tailwind-merge"
    
    show_progress "Adding form and validation libraries" \
        "pnpm add zod react-hook-form @hookform/resolvers"
    
    show_progress "Adding date and theme utilities" \
        "pnpm add date-fns next-themes sonner"
    
    # State Management
    show_progress "Adding state management" \
        "pnpm add zustand"
    
    # Development dependencies
    log_info "Installing development dependencies..."
    show_progress "Adding TypeScript and Prettier" \
        "pnpm add -D @types/node prettier prettier-plugin-tailwindcss @types/react @types/react-dom tailwindcss-animate"
    
    # Final install
    log_step "🔄 Running final dependency installation..."
    log_info "This step typically takes 1-3 minutes..."
    show_progress "Installing all dependencies" \
        "pnpm install"
    
    cd ..
    log_success "Frontend setup completed successfully! 🎉"
    
    # Show summary
    echo ""
    log_info "📋 Frontend Setup Summary:"
    echo "   ✅ Next.js 14 with TypeScript"
    echo "   ✅ Tailwind CSS for styling"
    echo "   ✅ Supabase for backend"
    echo "   ✅ Stripe for payments"
    echo "   ✅ Resend for emails"
    echo "   ✅ Radix UI components"
    echo "   ✅ Form handling with React Hook Form + Zod"
    echo "   ✅ State management with Zustand"
    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_step "Starting frontend-setup"
    setup_frontend
    log_success "frontend-setup completed!"
}

# Error handling
trap 'log_error "Module failed at line $LINENO"' ERR

# Execute main function
main "$@"