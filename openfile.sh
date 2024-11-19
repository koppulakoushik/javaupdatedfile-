#!/bin/bash

# Define the repository URL and the branch
REPO_URL="https://github.com/koppulakoushik/versionfiles.git"
BRANCH="main"  # Update this to your actual branch name
LOCAL_DIR="C:/Users/kkoppula/OneDrive - e2open, LLC/Desktop/script/versionfiles"  # Specified directory for cloning
FILENAME="version.txt"

# Add the directory to Git's safe list
git config --global --add safe.directory "$LOCAL_DIR"

# Clean up any existing directory
rm -rf "$LOCAL_DIR"

# Clone the repository
git clone -b "$BRANCH" "$REPO_URL" "$LOCAL_DIR"

# Change to the local repository directory
cd "$LOCAL_DIR"

# Function to process a single line
process_line() {
    local PARAMS="$1"
    local file1="${PARAMS##*_}"
    local ver="${file1%.txt}"
    local base="${PARAMS%_*}"
    local FILEPATH2="$PARAMS"
    GITHUB_API_URI="https://api.github.com/repos/adoptium/temurin${ver}-binaries/releases/latest"
    GITHUB_URI="https://github.com/adoptium/temurin${ver}-binaries/releases/latest"
    JAVA_LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' ${GITHUB_URI})
    JAVA_LATEST_VERSION=$(echo $JAVA_LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
    
    if [[ -f "$FILEPATH2" ]]; then
        local FLAVOR=$(cat "$FILEPATH2")
        echo "Checking the version file for version match"

        if [ "$JAVA_LATEST_VERSION" = "$FLAVOR" ]; then
            echo "There is no change to JDK Version today"
        else
            echo "You have $JAVA_LATEST_VERSION available for download. Proceeding to add E2open CA Certs"

            local DEST_ARTIFACTORY_URL="https://artifactory.dev.e2open.com/artifactory/ext-libs-dev/com/java/${ver}/OpenJDKU-${base}_hotspot/latest"
            local DEST_ARTIFACTORY_URL2="https://artifactory.dev.e2open.com/artifactory/ext-libs-dev/com/java/${ver}/OpenJDK-${base}_hotspot/${JAVA_LATEST_VERSION}"
            echo "${DEST_ARTIFACTORY_URL}"
            echo "${DEST_ARTIFACTORY_URL2}"

            local NEW_FILE_NAME="OpenJDK-${base}_hotspot-${JAVA_LATEST_VERSION}.tar.gz"

            echo "${DEST_ARTIFACTORY_URL}/file"
            echo "${DEST_ARTIFACTORY_URL2}/${NEW_FILE_NAME}"

            # Update the version in the file
            echo "$JAVA_LATEST_VERSION" > "$FILEPATH2"
        fi
    else
        echo "File does not exist: $FILEPATH2"
    fi
}

# Main script execution
if [[ -f "$FILENAME" ]]; then
    # Read the file line by line
    while IFS= read -r line || [ -n "$line" ]; do
        line=$(echo "$line" | tr -d '\r')
        process_line "$line"
    done < "$FILENAME"
    
    # Commit and push changes
    git add .
    git commit -m "Updated JDK versions"
    git push origin "$BRANCH"
else
    echo "File does not exist: $FILENAME"
fi
