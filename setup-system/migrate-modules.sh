#!/bin/bash
# migrate-modules.sh - Compatible Module Migration Tool
# Works with older bash versions and other shells

set -e

OLD_SCRIPT="setup-saas.sh"
NEW_MODULES_DIR="setup-system/modules"
TEMP_DIR="/tmp/module-migration"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Module mapping using regular arrays and functions
get_module_info() {
    local function_name=$1
    
    case "$function_name" in
        "print_module_01_content")
            echo "core/project-structure.sh|Project Structure Setup|Creates basic project directory structure"
            ;;
        "print_module_02_content")
            echo "core/frontend-setup.sh|Frontend Setup|Sets up Next.js frontend with dependencies"
            ;;
        "print_module_03_content")
            echo "core/supabase-setup.sh|Supabase Setup|Configures Supabase database and auth"
            ;;
        "print_module_04_content")
            echo "features/auth-system.sh|Authentication System|Sets up authentication with Supabase"
            ;;
        "print_module_05_content")
            echo "features/ui-components.sh|UI Components|Creates base UI component library"
            ;;
        "print_module_06_content")
            echo "features/payment-system.sh|Payment System|Integrates Stripe payment processing"
            ;;
        "print_module_07_content")
            echo "features/dashboard-setup.sh|Dashboard Setup|Creates dashboard pages and layouts"
            ;;
        "print_module_08_content")
            echo "advanced/email-system.sh|Email System|Sets up email with Resend and templates"
            ;;
        "print_module_09_content")
            echo "advanced/dev-tools.sh|Development Tools|Configures testing, CI/CD, and Docker"
            ;;
        *)
            echo ""
            ;;
    esac
}

# List of all module functions
MODULE_FUNCTIONS="
print_module_01_content
print_module_02_content
print_module_03_content
print_module_04_content
print_module_05_content
print_module_06_content
print_module_07_content
print_module_08_content
print_module_09_content
"

extract_module_content() {
    local function_name=$1
    local output_file=$2
    
    log_info "Extracting content from function: $function_name"
    
    # Extract function content between 'cat << 'MODULE_EOF'' and 'MODULE_EOF'
    awk "
        /^$function_name\(\) \{/ { in_function=1; next }
        in_function && /^cat << 'MODULE_EOF'/ { in_content=1; next }
        in_function && in_content && /^MODULE_EOF/ { in_content=0; in_function=0; next }
        in_function && in_content { print }
    " "$OLD_SCRIPT" > "$output_file"
    
    if [[ -s "$output_file" ]]; then
        log_success "Extracted $(wc -l < "$output_file") lines to $output_file"
        return 0
    else
        log_error "Failed to extract content for $function_name"
        return 1
    fi
}

create_module_header() {
    local module_path=$1
    local module_title=$2
    local module_description=$3
    local module_name=$(basename "$module_path" .sh)
    
    cat > "$TEMP_DIR/header.txt" << EOF
#!/bin/bash
# modules/$module_path
# Module: $module_title
# Version: 2.0.0
# Description: $module_description
# Depends: none
# Author: SaaS Template Team

set -e

# Module configuration
MODULE_NAME="$module_name"
MODULE_VERSION="2.0.0"
PROJECT_NAME=\${1:-"lean-saas-app"}

# Import shared utilities if available
if [[ -f "\$(dirname "\$0")/../../lib/logger.sh" ]]; then
    source "\$(dirname "\$0")/../../lib/logger.sh"
else
    # Fallback logging functions
    log_info() { echo -e "\033[0;34mℹ️  \$1\033[0m"; }
    log_success() { echo -e "\033[0;32m✅ \$1\033[0m"; }
    log_warning() { echo -e "\033[1;33m⚠️  \$1\033[0m"; }
    log_error() { echo -e "\033[0;31m❌ \$1\033[0m"; }
    log_step() { echo -e "\033[0;35m🚀 \$1\033[0m"; }
fi

# ==============================================================================
# MODULE FUNCTIONS
# ==============================================================================

EOF
}

create_module_footer() {
    local module_name=$1
    
    cat > "$TEMP_DIR/footer.txt" << EOF

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_step "Starting $module_name"
    setup_$module_name
    log_success "$module_name completed!"
}

# Error handling
trap 'log_error "Module failed at line \$LINENO"' ERR

# Execute main function
main "\$@"
EOF
}

migrate_single_module() {
    local function_name=$1
    local module_info=$(get_module_info "$function_name")
    
    if [[ -z "$module_info" ]]; then
        log_warning "No mapping found for function: $function_name"
        return 1
    fi
    
    # Parse module info using IFS
    local OLD_IFS=$IFS
    IFS='|'
    set -- $module_info
    local module_path=$1
    local module_title=$2
    local module_description=$3
    IFS=$OLD_IFS
    
    local category=$(dirname "$module_path")
    local module_file=$(basename "$module_path")
    local module_name=$(basename "$module_path" .sh)
    local full_output_path="$NEW_MODULES_DIR/$module_path"
    
    log_info "Migrating: $function_name -> $module_path"
    
    # Create category directory
    mkdir -p "$NEW_MODULES_DIR/$category"
    
    # Extract module content
    if extract_module_content "$function_name" "$TEMP_DIR/content.txt"; then
        # Create module header
        create_module_header "$module_path" "$module_title" "$module_description"
        
        # Create module footer
        create_module_footer "$module_name"
        
        # Combine header + content + footer
        cat "$TEMP_DIR/header.txt" "$TEMP_DIR/content.txt" "$TEMP_DIR/footer.txt" > "$full_output_path"
        
        # Make executable
        chmod +x "$full_output_path"
        
        log_success "Created module: $full_output_path"
        
        # Clean up temp files
        rm -f "$TEMP_DIR/header.txt" "$TEMP_DIR/content.txt" "$TEMP_DIR/footer.txt"
        
        return 0
    else
        log_error "Failed to migrate: $function_name"
        return 1
    fi
}

validate_old_script() {
    if [[ ! -f "$OLD_SCRIPT" ]]; then
        log_error "Old script not found: $OLD_SCRIPT"
        exit 1
    fi
    
    log_info "Validating old script: $OLD_SCRIPT"
    
    # Check if script contains expected functions
    local missing_functions=""
    for function_name in $MODULE_FUNCTIONS; do
        if ! grep -q "^$function_name()" "$OLD_SCRIPT"; then
            missing_functions="$missing_functions $function_name"
        fi
    done
    
    if [[ -n "$missing_functions" ]]; then
        log_warning "Missing functions in old script:$missing_functions"
    else
        log_success "All expected functions found in old script"
    fi
}

setup_new_structure() {
    log_info "Setting up new directory structure..."
    
    # Create main directories
    mkdir -p "$NEW_MODULES_DIR"/{core,features,advanced}
    mkdir -p setup-system/{templates,lib,config,docs}
    
    log_success "Directory structure created"
}

migrate_all_modules() {
    log_info "Starting migration of all modules..."
    
    local success_count=0
    local total_count=0
    
    for function_name in $MODULE_FUNCTIONS; do
        if [[ -n "$function_name" ]]; then
            total_count=$((total_count + 1))
            if migrate_single_module "$function_name"; then
                success_count=$((success_count + 1))
            fi
        fi
    done
    
    log_info "Migration complete: $success_count/$total_count modules migrated"
    
    if [[ $success_count -eq $total_count ]]; then
        log_success "All modules migrated successfully!"
    else
        log_warning "Some modules failed to migrate"
    fi
}

create_module_index() {
    log_info "Creating module index..."
    
    cat > "$NEW_MODULES_DIR/index.md" << 'INDEX'
# SaaS Setup Modules

## Core Modules
Essential modules required for basic SaaS setup.

- **project-structure** - Creates basic project directory structure
- **frontend-setup** - Sets up Next.js frontend with dependencies  
- **supabase-setup** - Configures Supabase database and authentication

## Feature Modules
Feature-specific modules that add functionality.

- **auth-system** - Sets up authentication with Supabase
- **ui-components** - Creates base UI component library
- **payment-system** - Integrates Stripe payment processing
- **dashboard-setup** - Creates dashboard pages and layouts

## Advanced Modules
Advanced features for production-ready applications.

- **email-system** - Sets up email with Resend and templates
- **dev-tools** - Configures testing, CI/CD, and Docker

## Usage

Each module can be run independently:
```bash
# Run individual module
./modules/core/project-structure.sh my-project

# Or through the orchestrator
./saas-setup.sh my-project lean-saas
```

## Module Development

See [module-development.md](../docs/module-development.md) for guidelines on creating new modules.
INDEX

    log_success "Module index created"
}

show_migration_summary() {
    echo ""
    log_success "Migration Summary:"
    echo ""
    
    log_info "📁 Directory structure:"
    if command -v tree >/dev/null 2>&1; then
        tree "$NEW_MODULES_DIR" 2>/dev/null
    else
        find "$NEW_MODULES_DIR" -type f -name "*.sh" | sort
    fi
    
    echo ""
    log_info "📋 Next steps:"
    echo "  1. Review migrated modules in: $NEW_MODULES_DIR"
    echo "  2. Test individual modules"
    echo "  3. Copy shared utilities to setup-system/lib/"
    echo "  4. Copy template configurations to setup-system/templates/"
    echo "  5. Copy main orchestrator to setup-system/saas-setup.sh"
    echo "  6. Test complete system"
    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "🔄 Starting SaaS Module Migration (Compatible Version)"
    echo ""
    
    # Setup
    mkdir -p "$TEMP_DIR"
    trap "rm -rf $TEMP_DIR" EXIT
    
    # Validate and migrate
    validate_old_script
    setup_new_structure
    migrate_all_modules
    create_module_index
    show_migration_summary
    
    log_success "🎉 Migration completed!"
}

# Check for help flag
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat << 'HELP'
SaaS Module Migration Tool (Compatible Version)

USAGE:
    ./migrate-modules.sh

DESCRIPTION:
    Automatically extracts modules from the old monolithic script
    and creates independent module files in the new structure.
    Compatible with older bash versions and other shells.

REQUIREMENTS:
    - Old script: setup-saas.sh (in current directory)
    - Write permissions in current directory

OUTPUT:
    - setup-system/modules/ - Independent module files
    - Module index and documentation

HELP
    exit 0
fi

# Execute main function
main "$@"