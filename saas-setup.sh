#!/bin/bash
# saas-setup.sh - Modern SaaS Template Orchestrator - UPDATED: Fixed working directory handling
# A lightweight, extensible setup system for SaaS applications

set -e

# ==============================================================================
# CONFIGURATION & CONSTANTS
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
LIB_DIR="$SCRIPT_DIR/lib"
CONFIG_DIR="$SCRIPT_DIR/config"

PROJECT_NAME=${1:-"lean-saas-app"}
TEMPLATE=${2:-"lean-saas"}

# Global array for discovered modules
declare -a DISCOVERED_MODULES

# Source shared utilities
source "$LIB_DIR/logger.sh"
source "$LIB_DIR/module-runner.sh"
source "$LIB_DIR/validator.sh"
source "$LIB_DIR/helpers.sh"

# ==============================================================================
# MAIN ORCHESTRATOR LOGIC
# ==============================================================================

show_banner() {
    echo ""
    log_header "🚀 SaaS Template Generator v2.0"
    echo ""
    log_info "Project: $PROJECT_NAME"
    log_info "Template: $TEMPLATE"
    log_info "Script Directory: $SCRIPT_DIR"
    echo ""
}

validate_environment() {
    log_step "Validating environment..."
    
    # Check required directories
    validate_directory "$MODULES_DIR" "Modules directory"
    validate_directory "$TEMPLATES_DIR" "Templates directory" 
    validate_directory "$LIB_DIR" "Library directory"
    
    # Check dependencies
    validate_command "node" "Node.js"
    validate_command "git" "Git"
    
    log_success "Environment validation completed"
}

load_template_config() {
    local template_file="$TEMPLATES_DIR/$TEMPLATE.yaml"
    
    if [[ ! -f "$template_file" ]]; then
        log_error "Template '$TEMPLATE' not found at: $template_file"
        log_info "Available templates:"
        list_available_templates
        exit 1
    fi
    
    log_info "Loading template configuration: $template_file"
    export TEMPLATE_CONFIG="$template_file"
}

list_available_templates() {
    for template in "$TEMPLATES_DIR"/*.yaml; do
        if [[ -f "$template" ]]; then
            local name=$(basename "$template" .yaml)
            local description=$(get_yaml_value "$template" "description")
            log_info "  - $name: $description"
        fi
    done
}

discover_modules() {
    log_step "Discovering available modules..."
    
    # Clear the array
    DISCOVERED_MODULES=()
    
    # Get modules from template config
    while IFS= read -r module; do
        if [[ -n "$module" ]]; then
            local module_file=$(find_module_file "$module")
            if [[ -n "$module_file" ]]; then
                DISCOVERED_MODULES+=("$module_file")
                log_info "Found module: $module ($module_file)"
            else
                log_warning "Module not found: $module"
            fi
        fi
    done < <(parse_yaml_array "$TEMPLATE_CONFIG" "modules")
    
    log_success "Discovered ${#DISCOVERED_MODULES[@]} modules"
}

validate_module_dependencies() {
    log_step "Validating module dependencies..."
    
    for module_file in "${DISCOVERED_MODULES[@]}"; do
        validate_module_file "$module_file"
    done
    
    log_success "All modules validated"
}

execute_modules() {
    log_step "Executing modules in sequence..."
    
    local executed_count=0
    local original_dir=$(pwd)
    
    for module_file in "${DISCOVERED_MODULES[@]}"; do
        local module_name=$(get_module_name "$module_file")
        
        log_info "Executing module: $module_name"
        
        # Special handling for project-structure module
        if [[ "$module_name" == "project-structure" ]]; then
            # Run project-structure from original directory
            cd "$original_dir"
            if run_module "$module_file" "$PROJECT_NAME"; then
                log_success "Module completed: $module_name"
                ((executed_count++))
                
                # After project-structure, change to project directory
                if [[ -d "$PROJECT_NAME" ]]; then
                    cd "$PROJECT_NAME"
                    log_info "Changed working directory to: $(pwd)"
                else
                    log_error "Project directory not created: $PROJECT_NAME"
                    exit 1
                fi
            else
                log_error "Module failed: $module_name"
                exit 1
            fi
        else
            # Run other modules from project directory
            if run_module "$module_file" "$PROJECT_NAME"; then
                log_success "Module completed: $module_name"
                ((executed_count++))
            else
                log_error "Module failed: $module_name"
                exit 1
            fi
        fi
    done
    
    # Return to original directory
    cd "$original_dir"
    
    if [[ $executed_count -gt 0 ]]; then
        log_success "All $executed_count modules executed successfully"
    else
        log_warning "No modules were executed"
    fi
}

show_completion_summary() {
    echo ""
    log_header "✨ SaaS Template Generation Complete!"
    echo ""
    
    log_info "Project created: $PROJECT_NAME"
    log_info "Template used: $TEMPLATE"
    log_info "Modules executed: ${#DISCOVERED_MODULES[@]}"
    
    echo ""
    log_step "Next Steps:"
    echo "  1. cd $PROJECT_NAME"
    echo "  2. cp frontend/.env.local.example frontend/.env.local"
    echo "  3. Edit environment variables"
    echo "  4. cd supabase && supabase start"
    echo "  5. cd frontend && pnpm install && pnpm dev"
    echo ""
    
    log_success "Happy building! 🚀"
    echo ""
}

show_help() {
    cat << 'HELP'
🚀 SaaS Template Generator v2.0

USAGE:
    ./saas-setup.sh [PROJECT_NAME] [TEMPLATE]

PARAMETERS:
    PROJECT_NAME    Name of the project to create (default: lean-saas-app)
    TEMPLATE        Template to use (default: lean-saas)

EXAMPLES:
    ./saas-setup.sh my-startup                    # Use default lean-saas template
    ./saas-setup.sh my-app full-saas             # Use full-saas template
    ./saas-setup.sh prototype minimal            # Use minimal template

AVAILABLE COMMANDS:
    ./saas-setup.sh --list-templates             # List available templates
    ./saas-setup.sh --list-modules               # List available modules
    ./saas-setup.sh --validate                   # Validate environment only
    ./saas-setup.sh --help                       # Show this help

DEVELOPMENT:
    ./saas-setup.sh --dev [PROJECT_NAME]         # Development mode with verbose logging

For more information, visit: https://github.com/your-repo/saas-template
HELP
}

list_modules() {
    log_info "Available modules:"
    
    for category in "$MODULES_DIR"/*; do
        if [[ -d "$category" ]]; then
            local cat_name=$(basename "$category")
            log_info "  📁 $cat_name/"
            
            for module in "$category"/*.sh; do
                if [[ -f "$module" ]]; then
                    local mod_name=$(basename "$module" .sh)
                    local description=$(get_module_description "$module")
                    log_info "    - $mod_name: $description"
                fi
            done
        fi
    done
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    # Handle special commands
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --list-templates)
            list_available_templates
            exit 0
            ;;
        --list-modules)
            list_modules
            exit 0
            ;;
        --validate)
            show_banner
            validate_environment
            log_success "Environment is valid"
            exit 0
            ;;
        --dev)
            export DEBUG=1
            PROJECT_NAME=${2:-"dev-saas-app"}
            TEMPLATE=${3:-"lean-saas"}
            ;;
    esac
    
    # Main execution flow
    show_banner
    validate_environment
    load_template_config
    discover_modules
    validate_module_dependencies
    execute_modules
    show_completion_summary
}

# Error handling
trap 'log_error "Script failed at line $LINENO"' ERR

# Execute main function
main "$@"