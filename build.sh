#!/bin/bash
set -e

# Configuration
REPO="JustinIven/smtp-oauth-relay"
IMAGE_NAME="smtp-oauth-relay-distroless"

# Function to get the latest release tag from GitHub
get_latest_release() {
    curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Determine which tag to build
TAG=$1
if [ -z "$TAG" ]; then
    echo "No tag provided, fetching latest release from GitHub..."
    TAG=$(get_latest_release)
    if [ -z "$TAG" ]; then
        echo "Warning: Could not find latest release via API, falling back to 'main'"
        TAG="main"
    fi
fi

echo "Target version: $TAG"

# Create a temporary directory for the build context
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "Cloning $REPO ($TAG) into $BUILD_DIR..."
git clone --depth 1 --branch "$TAG" "https://github.com/$REPO.git" "$BUILD_DIR/source"

# Copy the Dockerfile from this repository into the build context
cp Dockerfile "$BUILD_DIR/source/Dockerfile"

# Build the Docker image
# We use the tag as the docker tag (stripping 'v' prefix if it exists)
DOCKER_TAG=$(echo "$TAG" | sed 's/^v//')

echo "Building Docker image $IMAGE_NAME:$DOCKER_TAG..."
docker build -t "$IMAGE_NAME:$DOCKER_TAG" "$BUILD_DIR/source"

echo "------------------------------------------------"
echo "Build complete: $IMAGE_NAME:$DOCKER_TAG"
echo "To run the container:"
echo "  docker run -p 8025:8025 $IMAGE_NAME:$DOCKER_TAG"
