#!/bin/bash
# Module 1: Project Structure Setup

PROJECT_NAME=$1
log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }

setup_project_structure() {
    log_info "Creating project structure for $PROJECT_NAME..."
    
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    
    # Main directories (don't create frontend subdirectories yet)
    mkdir -p {supabase,shared,docs,.vscode,scripts}
    
    # Supabase subdirectories
    mkdir -p supabase/{functions,migrations,seed,policies}
    mkdir -p supabase/functions/{stripe-webhook,send-email,user-management}
    
    # Shared subdirectories
    mkdir -p shared/{types,utils,constants,schemas}
    
    log_success "Project structure created"
}

setup_project_structure $1
