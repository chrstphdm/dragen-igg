#!/bin/bash

set -e

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
    echo "Need a version as argument."
    exit 1
fi
VERSION=$1

RELEASE_NAME="dragen-igg-${VERSION}"
rm -rf "${RELEASE_NAME}"

echo "Creating ${RELEASE_NAME}..."
mkdir -p "${RELEASE_NAME}"

echo "Copying files..."
cp -r ../dragen-igg ../create_batches ../create_version ../batch_submitter ../assets ../conf ../docs ../lib ../modules ../scripts ../workflows ../main.nf ../nextflow.config "${RELEASE_NAME}/."

echo "Archiving release file..."
cd "${RELEASE_NAME}" || exit
tar -cvzf "../${RELEASE_NAME}.tar.gz" .

echo "Cleaning..."
cd ..
rm -rf "${RELEASE_NAME}"

# Checks if the tag already exists
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo "The tag $VERSION already exists. Moving to the current commit..."
    # Moves the tag to the current commit (forces with -f)
    git tag -f "$VERSION"
else
    echo "Creating the tag $VERSION at the current commit..."
    # Creates the tag at the current commit
    git tag "$VERSION"
fi

echo "Done..."
