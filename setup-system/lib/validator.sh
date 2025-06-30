
# Validation utilities

validate_directory() {
    local dir=$1
    local description=$2
    
    if [[ ! -d "$dir" ]]; then
        log_error "$description not found: $dir"
        return 1
    fi
    
    log_debug "$description validated: $dir"
    return 0
}

validate_file() {
    local file=$1
    local description=$2
    
    if [[ ! -f "$file" ]]; then
        log_error "$description not found: $file"
        return 1
    fi
    
    log_debug "$description validated: $file"
    return 0
}

validate_command() {
    local cmd=$1
    local description=$2
    
    if ! command -v "$cmd" &> /dev/null; then
        log_error "$description not found: $cmd"
        log_info "Please install $description and try again"
        return 1
    fi
    
    log_debug "$description found: $(which $cmd)"
    return 0
}

validate_module_file() {
    local module_file=$1
    
    if [[ ! -f "$module_file" ]]; then
        log_error "Module file not found: $module_file"
        return 1
    fi
    
    if [[ ! -x "$module_file" ]]; then
        log_error "Module file not executable: $module_file"
        return 1
    fi
    
    # Check if module has required functions
    if ! grep -q "setup_" "$module_file"; then
        log_warning "Module may not have setup function: $module_file"
    fi
    
    return 0
}

validate_yaml_file() {
    local yaml_file=$1
    
    if ! command -v yq &> /dev/null; then
        log_debug "yq not available, skipping YAML validation"
        return 0
    fi
    
    if ! yq eval '.' "$yaml_file" &> /dev/null; then
        log_error "Invalid YAML file: $yaml_file"
        return 1
    fi
    
    return 0
}