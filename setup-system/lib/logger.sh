# lib/logger.sh - Logging utilities

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging functions
log_info() { 
    echo -e "${BLUE}ℹ️  $1${NC}" 
}

log_success() { 
    echo -e "${GREEN}✅ $1${NC}" 
}

log_warning() { 
    echo -e "${YELLOW}⚠️  $1${NC}" 
}

log_error() { 
    echo -e "${RED}❌ $1${NC}" >&2
}

log_step() { 
    echo -e "${PURPLE}🚀 $1${NC}" 
}

log_header() {
    echo -e "${BOLD}${CYAN}$1${NC}"
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${CYAN}🔍 DEBUG: $1${NC}" >&2
    fi
}

# Progress indicator
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    local percent=$((current * 100 / total))
    
    printf "\r${BLUE}Progress: [%3d%%] %s${NC}" "$percent" "$message"
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}
