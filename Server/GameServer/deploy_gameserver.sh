#!/bin/bash
# =============================================================
# GameServer Deployment Script
# Run this on the Linux production server to finalize migration
# =============================================================
# Usage: bash deploy_gameserver.sh
# IMPORTANT: Review each step before executing!

set -e
UBUNTU_HOME=/home/ubuntu
BACKUP_DIR="${UBUNTU_HOME}/backup_$(date +%Y%m%d_%H%M%S)"

echo "=== GameServer Migration Deployment ==="
echo "Backup dir: ${BACKUP_DIR}"
echo ""

# Step 1: Create backup directory
echo "[Step 1] Creating backup directory..."
mkdir -p "${BACKUP_DIR}"

# Step 2: Stop all running servers
echo "[Step 2] Please stop all running servers first!"
echo "Press Enter when all servers are stopped..."
read -r

# Step 3: Backup Manager8
echo "[Step 3] Archiving Manager8/ to backup..."
if [ -d "${UBUNTU_HOME}/Manager8" ]; then
    mv "${UBUNTU_HOME}/Manager8" "${BACKUP_DIR}/Manager8"
    echo "  Manager8 archived to ${BACKUP_DIR}/Manager8"
else
    echo "  Manager8 not found, skipping"
fi

# Step 4: Backup original Game2
echo "[Step 4] Archiving Game2/ to backup..."
if [ -d "${UBUNTU_HOME}/Game2" ]; then
    mv "${UBUNTU_HOME}/Game2" "${BACKUP_DIR}/Game2"
    echo "  Game2 archived to ${BACKUP_DIR}/Game2"
else
    echo "  Game2 not found, skipping"
fi

# Step 5: Deploy GameServer
echo "[Step 5] Deploying GameServer..."
# GameServer should already be uploaded to ${UBUNTU_HOME}/GameServer
if [ -d "${UBUNTU_HOME}/GameServer" ]; then
    echo "  GameServer directory found"
    chmod +x "${UBUNTU_HOME}/GameServer/r.sh"
    chmod +x "${UBUNTU_HOME}/GameServer/r_DataCenter.sh"
    chmod +x "${UBUNTU_HOME}/GameServer/r_tool.sh"
    chmod +x "${UBUNTU_HOME}/GameServer/nc.sh"
    echo "  Shell scripts made executable"
else
    echo "  ERROR: GameServer directory not found!"
    echo "  Upload the GameServer directory to ${UBUNTU_HOME}/ first"
    exit 1
fi

# Step 6: Verify configs directory
echo "[Step 6] Verifying configs directory..."
if [ -d "${UBUNTU_HOME}/configs" ]; then
    CONFIG_COUNT=$(find "${UBUNTU_HOME}/configs" -type f | wc -l)
    echo "  configs/ found with ${CONFIG_COUNT} files"
else
    echo "  ERROR: configs/ directory not found!"
    exit 1
fi

# Step 7: Verify confs directory
echo "[Step 7] Verifying confs directory..."
if [ -d "${UBUNTU_HOME}/confs" ]; then
    echo "  confs/ found"
    ls -la "${UBUNTU_HOME}/confs/"
else
    # Try to copy from GameServer if it exists there
    if [ -d "${UBUNTU_HOME}/GameServer/confs" ]; then
        mv "${UBUNTU_HOME}/GameServer/confs" "${UBUNTU_HOME}/confs"
        echo "  confs/ moved from GameServer to top-level"
    else
        echo "  WARNING: confs/ directory not found"
    fi
fi

# Step 8: Verify Game_2 (content resources)
echo "[Step 8] Verifying Game_2/ resources..."
if [ -d "${UBUNTU_HOME}/Game_2" ]; then
    echo "  Game_2/Script: $(find ${UBUNTU_HOME}/Game_2/Script -type f 2>/dev/null | wc -l) files"
    echo "  Game_2/Scene: $(find ${UBUNTU_HOME}/Game_2/Scene -type f 2>/dev/null | wc -l) files"
else
    echo "  WARNING: Game_2/ not found"
fi

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "To start Manager mode:"
echo "  cd ${UBUNTU_HOME}/GameServer && bash r.sh publish_yu 8 Manager"
echo ""
echo "To start Game mode:"
echo "  cd ${UBUNTU_HOME}/GameServer && bash r.sh publish_yu 2 Game"
echo ""
echo "Backup location: ${BACKUP_DIR}"
