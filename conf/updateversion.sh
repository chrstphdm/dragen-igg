echo $1;
CI_COMMIT_TAG=$1;
VERSION=$(echo $CI_COMMIT_TAG   | cut -d "-" -f2-) &&   sed -i "s/version.*/version=\'$VERSION\'/" manifest.config