#!/bin/bash
#
# update.sh
# Downloads and extracts MarkdownMasterCMS app|full tarball
#
# Usage: scripts/update.sh <stable|unstable>
#        Or: export UPDATE_SOURCE=stable && scripts/update.sh
#
# Environment variable: UPDATE_SOURCE (stable|unstable) - optional, overrides command-line arg
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"

# Configuration
BASE_URL="https://markdownmaster.com/build"
GITHUB_URL="https://github.com/eVAL-Agency/MarkdownMasterCMS/releases/download"

# Determine UPDATE_SOURCE: env var > command-line arg > default error
if [[ $# -ge 1 ]]; then
    UPDATE_SOURCE="$1"
fi

# Check if UPDATE_SOURCE is set (either from env or passed as arg)
if [[ -z "$UPDATE_SOURCE" ]]; then
    # Try to read from .env file
    if [[ -f "$ENV_FILE" ]]; then
        source "$ENV_FILE"
        if [[ -n "${UPDATE_SOURCE:-}" ]]; then
            echo "Using UPDATE_SOURCE from $ENV_FILE: $UPDATE_SOURCE"
        fi
    else
        echo "Error: No UPDATE_SOURCE specified. Usage:" >&2
        echo "  $0 <stable|unstable>" >&2
        exit 1
    fi
else
    # UPDATE_SOURCE was provided, save to .env if it doesn't exist or update existing
    if [[ ! -f "$ENV_FILE" ]] || ! grep -q "^UPDATE_SOURCE=" "$ENV_FILE" 2>/dev/null; then
        echo "UPDATE_SOURCE=$UPDATE_SOURCE" > "$ENV_FILE"
        echo "Saved UPDATE_SOURCE=$UPDATE_SOURCE to $ENV_FILE"
    else
        # Update existing .env file
        sed -i "s/^UPDATE_SOURCE=.*/UPDATE_SOURCE=$UPDATE_SOURCE/" "$ENV_FILE"
        echo "Updated UPDATE_SOURCE=$UPDATE_SOURCE in $ENV_FILE"
    fi
fi

# Validate UPDATE_SOURCE value
if [[ "$UPDATE_SOURCE" != "stable" && "$UPDATE_SOURCE" != "unstable" ]]; then
    echo "Error: Invalid UPDATE_SOURCE '$UPDATE_SOURCE'. Must be 'stable' or 'unstable'" >&2
    exit 1
fi

# Determine which tarball to download based on project structure
if [ -e "$PROJECT_ROOT/themes/" ]; then
    # If themes/ exists, presume the user only wants the base application
    SCRIPT_NAME="markdownmaster-app"
else
    # If themes/ does NOT exist, download the full version with demo files
    SCRIPT_NAME="markdownmaster-full"
fi

# Determine the tarball URL and filename
if [[ "$UPDATE_SOURCE" == "unstable" ]]; then
    TARBALL_URL="${BASE_URL}/${SCRIPT_NAME}-unstable.tgz"
    TARBALL_NAME="${SCRIPT_NAME}-unstable.tgz"
else
    # For stable, get latest release from GitHub API
    # Fetch the latest release asset name using jq to extract version
    RELEASE_INFO=$(curl -sL "https://api.github.com/repos/eVAL-Agency/MarkdownMasterCMS/releases/latest")
    
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is required but not installed. Install with:" >&2
        echo "  Ubuntu/Debian: sudo apt-get install jq" >&2
        echo "  macOS: brew install jq" >&2
        echo "  RHEL/CentOS: sudo yum install jq" >&2
        exit 1
    fi
    
    # Extract the tarball asset name from the latest release
    TARBALL_URL=$(echo "$RELEASE_INFO" | jq -r '.assets[] | select(.name | contains("'$SCRIPT_NAME'")) | .browser_download_url' | head -n1)
    
    if [[ -z "$TARBALL_URL" ]]; then
        echo "Error: No .tgz asset found in latest release" >&2
        exit 1
    fi

    TARBALL_NAME="$(basename "$TARBALL_URL")"
fi

# Output info
echo "UPDATE_SOURCE: $UPDATE_SOURCE"
echo "Downloading: $TARBALL_URL"
echo "Extracting to: $PROJECT_ROOT"
echo ""

# Create temporary directory for extraction
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Download the tarball
echo "Fetching tarball..."
curl -L -o "$TEMP_DIR/${TARBALL_NAME}" "$TARBALL_URL"

# Extract to current directory (strip top-level directory)
echo "Extracting to $(pwd)..."
tar -xzf "$TEMP_DIR/${TARBALL_NAME}" -C "$PROJECT_ROOT" --overwrite

echo ""
echo "Done! Extracted: $TARBALL_NAME"
