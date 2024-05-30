#!/bin/bash

set -e

MODULE_FOLDER="/mnt/software/MY_ORG_SOFTWARE/modulefiles/dragen-igg"
INSTALL_FOLDER="/mnt/software/MY_ORG_SOFTWARE/opt/DRAGEN-IGG"

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
    echo "Need a version as argument."
    exit 1
fi
VERSION=$1

###########################################################
ARCHIVE_NAME="dragen-igg-${VERSION}.tar.gz"
## INSTALL RELEASE
if [ ! -e "${ARCHIVE_NAME}" ] ; then
    echo "Release file ${ARCHIVE_NAME} must exists"
    exit 1
fi

echo "Copying [${ARCHIVE_NAME}] to [${INSTALL_FOLDER}]...."
cp "${ARCHIVE_NAME}" "${INSTALL_FOLDER}"

echo "Jump in install folder...."
cd "${INSTALL_FOLDER}" || exit

echo "Creating folder [${INSTALL_FOLDER}/${VERSION}]...."
mkdir -p "${INSTALL_FOLDER}/${VERSION}"

echo "Creating folder [${INSTALL_FOLDER}/${VERSION}/src]...."
mkdir -p "${INSTALL_FOLDER}/${VERSION}/src"

echo "Creating folder [${INSTALL_FOLDER}/${VERSION}/bin]...."
mkdir -p "${INSTALL_FOLDER}/${VERSION}/bin"

echo "Creating folder [${INSTALL_FOLDER}/${VERSION}/bin/man]...."
mkdir -p "${INSTALL_FOLDER}/${VERSION}/bin/man"

echo "Unpacking...."
tar -xvzf "${ARCHIVE_NAME}" -C "${INSTALL_FOLDER}/${VERSION}/src"

echo "Create links"
ln -fs "${INSTALL_FOLDER}/${VERSION}/src/dragen-igg" "${INSTALL_FOLDER}/${VERSION}/bin/dragen-igg"
# ln -fs "${INSTALL_FOLDER}/${VERSION}/src/man/dragen-igg" "${INSTALL_FOLDER}/${VERSION}/bin/man/."
ln -fs "${INSTALL_FOLDER}/${VERSION}/src/create_batches" "${INSTALL_FOLDER}/${VERSION}/bin/create_batches"
# ln -fs "${INSTALL_FOLDER}/${VERSION}/src/man/create_batches" "${INSTALL_FOLDER}/${VERSION}/bin/man/."
ln -fs "${INSTALL_FOLDER}/${VERSION}/src/batch_submitter" "${INSTALL_FOLDER}/${VERSION}/bin/batch_submitter"
# ln -fs "${INSTALL_FOLDER}/${VERSION}/src/man/batch_submitter" "${INSTALL_FOLDER}/${VERSION}/bin/man/."
ln -fs "${INSTALL_FOLDER}/${VERSION}/src/create_version" "${INSTALL_FOLDER}/${VERSION}/bin/create_version"
# ln -fs "${INSTALL_FOLDER}/${VERSION}/src/man/batch_submitter" "${INSTALL_FOLDER}/${VERSION}/bin/man/."

###########################################################
## MAKE IT AVAILABLE THROW MODULE
echo "Jump in module folder...."
cd "${MODULE_FOLDER}" || exit

echo "Writting the module file [${VERSION}] in [${MODULE_FOLDER}]...."
echo "#%Module1.0#####################################################################
##
## modules modulefile
##
## modulefiles/modules.  Generated from modules.in by configure.
##

module-whatis   \"loads the dragen-igg  environment\"

prepend-path    PATH                 ${INSTALL_FOLDER}/${VERSION}/bin
setenv          DRAGEN_IGG_DIR ${INSTALL_FOLDER}/${VERSION}/src
prepend-path    MANPATH              ${INSTALL_FOLDER}/${VERSION}/src/man" > "${MODULE_FOLDER}/${VERSION}"

echo "Set the ownership"
chown -R my_org_bioinfoadmin:g_my_org "${INSTALL_FOLDER}/${VERSION}"
chown -R my_org_bioinfoadmin:g_my_org "${MODULE_FOLDER}/${VERSION}"

echo "Set the chmod"
chmod -R 750 "${INSTALL_FOLDER}/${VERSION}"
chmod -R 750 "${MODULE_FOLDER}/${VERSION}"
