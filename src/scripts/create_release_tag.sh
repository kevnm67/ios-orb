#!/usr/bin/env bash
# Create and push a release tag.
# Env: VERSION_SOURCE - "git-describe" (default) or "marketing-version"
set -euo pipefail

VERSION_SOURCE="${VERSION_SOURCE:-git-describe}"

case "${VERSION_SOURCE}" in
    git-describe)
        # Get latest tag and increment patch version
        LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")
        echo "-> Latest tag: ${LATEST_TAG}"

        # Strip leading 'v' if present
        VERSION="${LATEST_TAG#v}"

        # Split into major.minor.patch
        IFS='.' read -r MAJOR MINOR PATCH <<< "${VERSION}"
        PATCH=$((PATCH + 1))

        NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
        ;;
    marketing-version)
        # Read MARKETING_VERSION from xcodeproj build settings
        NEW_VERSION=$(xcodebuild -showBuildSettings 2>/dev/null \
            | grep "MARKETING_VERSION" \
            | head -1 \
            | awk '{print $NF}')

        if [[ -z "${NEW_VERSION}" ]]; then
            echo "Error: Could not read MARKETING_VERSION from Xcode project"
            exit 1
        fi
        ;;
    *)
        echo "Error: Unknown version_source '${VERSION_SOURCE}'. Use 'git-describe' or 'marketing-version'."
        exit 1
        ;;
esac

NEW_TAG="v${NEW_VERSION}"
echo "-> Creating tag: ${NEW_TAG}"

# Check if tag already exists
if git rev-parse "${NEW_TAG}" &>/dev/null; then
    echo "Tag ${NEW_TAG} already exists. Skipping."
    exit 0
fi

git tag -a "${NEW_TAG}" -m "Release ${NEW_TAG}"
git push origin "${NEW_TAG}"

echo "-> Tag ${NEW_TAG} created and pushed"
