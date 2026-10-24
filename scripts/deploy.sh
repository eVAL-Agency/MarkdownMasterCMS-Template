#!/bin/bash
#
# deploy.sh
# Deploys MarkdownMasterCMS to production server via rsync
#
# Usage: scripts/deploy.sh [local|remote] [destination]
#        Or: export DEPLOY_MODE=remote && export DEPLOY_HOST=... && scripts/deploy.sh
#
# Environment variables (from .env):
#   DEPLOY_MODE - local or remote (default: local)
#   DEPLOY_HOST - production server hostname (required for remote)
#   DEPLOY_USER - SSH username for production server
#   DEPLOY_PATH - full path on remote server (e.g., /var/www/html/markdownmaster)
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"

# Default values
DEPLOY_MODE="${DEPLOY_MODE:-local}"
DEPLOY_HOST="${DEPLOY_HOST:-}"
DEPLOY_USER="${DEPLOY_USER:-}"
DEPLOY_PATH="${DEPLOY_PATH:-}"

# Read from .env if it exists
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
fi

# Validate DEPLOY_MODE
if [[ "$DEPLOY_MODE" != "local" && "$DEPLOY_MODE" != "remote" ]]; then
    echo "Error: Invalid DEPLOY_MODE '$DEPLOY_MODE'. Must be 'local' or 'remote'" >&2
    exit 1
fi

# For remote deployment, require host and user
if [[ "$DEPLOY_MODE" == "remote" ]]; then
    if [[ -z "$DEPLOY_HOST" ]]; then
        echo "Error: DEPLOY_HOST is required for remote deployment" >&2
        echo "Set in .env or via: export DEPLOY_HOST=your-server.com" >&2
        exit 1
    fi
    
    if [[ -z "$DEPLOY_USER" ]]; then
        echo "Error: DEPLOY_USER is required for remote deployment" >&2
        echo "Set in .env or via: export DEPLOY_USER=your-username" >&2
        exit 1
    fi
fi

if [[ -z "$DEPLOY_PATH" ]]; then
	echo "Error: DEPLOY_PATH is required for deployment" >&2
	echo "Set in .env or via: export DEPLOY_PATH=/var/www/somewhere" >&2
	exit 1
fi

# Determine source directories to sync
SOURCE_PATHS="app backend themes extras index.php"

echo "=== MarkdownMasterCMS Deployment ==="
echo "Mode: $DEPLOY_MODE"

if [[ "$DEPLOY_MODE" == "remote" ]]; then
    echo "Host: $DEPLOY_HOST"
    echo "User: $DEPLOY_USER"
    echo "Path: $DEPLOY_PATH"
else
    echo "Target: $DEPLOY_PATH"
fi
echo ""

# Build rsync command with exclude patterns for .git, node_modules, etc.
RSYNC_OPTS="-avz"

# Create deployment directory if it doesn't exist
if [[ "$DEPLOY_MODE" == "remote" ]]; then
    REMOTE_TARGET="$DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH"
    
    # Check SSH key availability
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no "$REMOTE_TARGET" "exit" 2>/dev/null; then
        echo "Warning: Could not connect to remote server. Ensure SSH keys are set up." >&2
        echo "Run: ssh-copy-id $DEPLOY_USER@$DEPLOY_HOST" >&2
    fi

    echo "Syncing to remote server..."
    echo "Command: rsync $RSYNC_OPTS $SOURCE_PATHS => $REMOTE_TARGET/"
    
    # Perform the rsync
    for SOURCE in $SOURCE_PATHS; do
    	rsync $RSYNC_OPTS "$SOURCE" "$REMOTE_TARGET/"
    done
    
    echo ""
    echo "Deployment complete!"
else
    echo "Command: rsync $RSYNC_OPTS $SOURCE_PATHS => $DEPLOY_PATH/"
     # Perform the rsync
	for SOURCE in $SOURCE_PATHS; do
		rsync $RSYNC_OPTS "$SOURCE" "$DEPLOY_PATH/"
	done
fi
