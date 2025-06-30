# Helper utilities

get_module_name() {
    local module_file=$1
    basename "$module_file" .sh | sed 's/^[0-9]*-//'
}

get_module_description() {
    local module_file=$1

    # Try to extract description from module file
    local desc=$(grep -m1 "^# Module.*:" "$module_file" | cut -d':' -f2- | sed 's/^ *//')

    if [[ -n "$desc" ]]; then
        echo "$desc"
    else
        echo "No description available"
    fi
}

find_module_file() {
    local module_name=$1

    # Search in all module directories
    for category_dir in "$MODULES_DIR"/*; do
        if [[ -d "$category_dir" ]]; then
            # Look for exact match
            local exact_match="$category_dir/$module_name.sh"
            if [[ -f "$exact_match" ]]; then
                echo "$exact_match"
                return 0
            fi

            # Look for pattern match (e.g., 01-project-structure.sh)
            local pattern_match=$(find "$category_dir" -name "*$module_name*.sh" | head -1)
            if [[ -n "$pattern_match" ]]; then
                echo "$pattern_match"
                return 0
            fi
        fi
    done

    return 1
}

parse_yaml_array() {
    local yaml_file=$1
    local key=$2

    if command -v yq &>/dev/null; then
        yq eval ".${key}[]" "$yaml_file" 2>/dev/null || echo ""
    else
        # Fallback: simple grep-based parsing
        grep -A 20 "$key:" "$yaml_file" | grep "^  -" | sed 's/^  - //' | tr '\n' ' '
    fi
}

get_yaml_value() {
    local yaml_file=$1
    local key=$2

    if command -v yq &>/dev/null; then
        yq eval ".$key" "$yaml_file" 2>/dev/null || echo ""
    else
        # Fallback: simple grep-based parsing
        grep "^$key:" "$yaml_file" | cut -d':' -f2- | sed 's/^ *//' | tr -d '"'
    fi
}

create_directory_if_missing() {
    local dir=$1
    local description=$2

    if [[ ! -d "$dir" ]]; then
        log_info "Creating $description: $dir"
        mkdir -p "$dir"
    fi
}

backup_file() {
    local file=$1

    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        log_debug "Backed up: $file -> $backup"
    fi
}
