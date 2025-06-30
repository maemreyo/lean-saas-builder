# Module execution utilities

run_module() {
    local module_file=$1
    local project_name=$2
    
    log_debug "Running module: $module_file with project: $project_name"
    
    # Make sure module is executable
    chmod +x "$module_file"
    
    # Run module with proper environment
    export PROJECT_NAME="$project_name"
    export TEMPLATE_CONFIG
    export DEBUG
    
    # Execute module and capture output
    if [[ "${DEBUG:-0}" == "1" ]]; then
        "$module_file" "$project_name"
    else
        "$module_file" "$project_name" 2>&1 | while IFS= read -r line; do
            log_debug "[$module_file] $line"
        done
    fi
    
    local exit_code=${PIPESTATUS[0]}
    
    if [[ $exit_code -eq 0 ]]; then
        log_debug "Module completed successfully: $module_file"
        return 0
    else
        log_error "Module failed with exit code $exit_code: $module_file"
        return $exit_code
    fi
}

get_module_metadata() {
    local module_file=$1
    
    # Extract metadata from module file header
    local name=$(get_module_name "$module_file")
    local description=$(get_module_description "$module_file")
    local version=$(grep "^# Version:" "$module_file" | cut -d':' -f2 | sed 's/^ *//')
    local dependencies=$(grep "^# Depends:" "$module_file" | cut -d':' -f2 | sed 's/^ *//')
    
    cat << EOF
{
  "name": "$name",
  "description": "$description",
  "version": "${version:-1.0.0}",
  "dependencies": "${dependencies:-}",
  "file": "$module_file"
}
EOF
}

check_module_dependencies() {
    local module_file=$1
    
    local dependencies=$(grep "^# Depends:" "$module_file" | cut -d':' -f2 | sed 's/^ *//')
    
    if [[ -n "$dependencies" ]]; then
        log_debug "Checking dependencies for $module_file: $dependencies"
        
        for dep in $dependencies; do
            local dep_file=$(find_module_file "$dep")
            if [[ -z "$dep_file" ]]; then
                log_error "Missing dependency: $dep (required by $(get_module_name "$module_file"))"
                return 1
            fi
        done
    fi
    
    return 0
}