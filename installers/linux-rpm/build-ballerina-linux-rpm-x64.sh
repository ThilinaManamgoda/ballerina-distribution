#!/bin/bash

function pringUsage() {
    echo "Usage:"
    echo "build.sh [options]"
    echo "options:"
    echo "    -v (--version)"
    echo "        version of the balletina distribution"
    echo "    -d (--dist)"
    echo "        balletina distribution type either of the followings"
    echo "        1. balletina-platform"
    echo "        2. ballerina-runtime"
    echo "    --all"
    echo "        build all ballerina distributions"
    echo "        this will OVERRIDE the -d option"
    echo "eg: build.sh -v 1.0.0 -d ballerina"
    echo "eg: build.sh -v 1.0.0 --all"
}

BUILD_ALL_DISTRIBUTIONS=false
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -v|--version)
    BALLERINA_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--dist)
    DISTRIBUTION="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

for i in "${POSITIONAL[@]}"
do
    if [ "$i" == "--all" ]; then
        BUILD_ALL_DISTRIBUTIONS=true
    fi
done

if [ -z "$BALLERINA_VERSION" ]; then
    echo "Please enter the version of the ballerina pack"
    pringUsage
    exit 1
fi

if [ -z "$DISTRIBUTION" ] && [ "$BUILD_ALL_DISTRIBUTIONS" == "false" ]; then
    echo "You have to use either --all or -d [distribution]"
    pringUsage
    exit 1
fi


BALLERINA_DISTRIBUTION_LOCATION=/home/ubuntu/Packs
BALLERINA_PLATFORM=ballerina-platform-linux-$BALLERINA_VERSION
BALLERINA_RUNTIME=ballerina-runtime-linux-$BALLERINA_VERSION
BALLERINA_INSTALL_DIRECTORY=ballerina-$BALLERINA_VERSION
BALDIST=ballerina-linux-$BALLERINA_VERSION
PLATFORM_SPEC_FILE="rpmbuild/SPECS/ballerina_platform.spec"
RUNTIME_SPEC_FILE="rpmbuild/SPECS/ballerina_runtime.spec"
RPM_BALLERINA_VERSION=""

echo $BALDIST "build started at" $(date +"%Y-%m-%d %H:%M:%S")


echo $BALDIST "build completed at" $(date +"%Y-%m-%d %H:%M:%S")


function extractPack() {
    echo "Extracting the ballerina distribution, " $1
    rm -rf rpmbuild/SOURCES
    mkdir -p rpmbuild/SOURCES
    unzip $1 -d rpmbuild/SOURCES/ > /dev/null 2>&1
}

# Remove "-" from the version since RPM Spec file doesn't support this syntax
# Globals:
#   BALLERINA_VERSION
# Arguments:
# Returns:
#   None
function rpm_version() {
    RPM_BALLERINA_VERSION=$(echo "${BALLERINA_VERSION//-/.}")
}

# Set variables in SPEC file
# Globals:
#   BALLERINA_VERSION
#   RPM_BALLERINA_VERSION
# Arguments:
# Returns:
#   None
function setupVersion_runtime() {
    sed -i "/Version:/c\Version:        ${RPM_BALLERINA_VERSION}" ${RUNTIME_SPEC_FILE}
    sed -i "/%define _ballerina_version/c\%define _ballerina_version ${BALLERINA_VERSION}" ${RUNTIME_SPEC_FILE}
    sed -i "/%define _ballerina_tools_dir/c\%define _ballerina_tools_dir ${BALLERINA_RUNTIME}" ${RUNTIME_SPEC_FILE}
    sed -i "s/export BALLERINA_HOME=/export BALLERINA_HOME=\/opt\/Ballerina\/ballerina-runtime-${BALLERINA_VERSION}/" ${RUNTIME_SPEC_FILE}
    sed -i "s?SED_BALLERINA_HOME?/opt/Ballerina/ballerina-runtime-${BALLERINA_VERSION}?" ${RUNTIME_SPEC_FILE}
}

# Set variables in SPEC file
# Globals:
#   BALLERINA_VERSION
#   RPM_BALLERINA_VERSION
# Arguments:
# Returns:
#   None
function setupVersion_platform() {
    sed -i "/Version:/c\Version:        ${RPM_BALLERINA_VERSION}" ${PLATFORM_SPEC_FILE}
    sed -i "/%define _ballerina_version/c\%define _ballerina_version ${BALLERINA_VERSION}" ${PLATFORM_SPEC_FILE}
    sed -i "/%define _ballerina_tools_dir/c\%define _ballerina_tools_dir ${BALLERINA_PLATFORM}" ${PLATFORM_SPEC_FILE}
    sed -i "s/export BALLERINA_HOME=/export BALLERINA_HOME=\/opt\/Ballerina\/ballerina-platform-${BALLERINA_VERSION}/" ${PLATFORM_SPEC_FILE}
    sed -i "s?SED_BALLERINA_HOME?/opt/Ballerina/ballerina-platform-${BALLERINA_VERSION}?" ${PLATFORM_SPEC_FILE}
}

function createBallerinaPlatform() {
    echo "Creating ballerina platform installer"
    extractPack "$BALLERINA_DISTRIBUTION_LOCATION/$BALLERINA_PLATFORM.zip"
    setupVersion_platform
    rpmbuild -bb --define "_topdir  $(pwd)/rpmbuild" ${PLATFORM_SPEC_FILE}

}

function createBallerinaRuntime() {
    echo "Creating ballerina runtime installer"
    extractPack "$BALLERINA_DISTRIBUTION_LOCATION/$BALLERINA_RUNTIME.zip"
    setupVersion_runtime
    rpmbuild -bb --define "_topdir  $(pwd)/rpmbuild" ${RUNTIME_SPEC_FILE}
}


rpm_version
if [ "$BUILD_ALL_DISTRIBUTIONS" == "true" ]; then
    echo "Creating all distributions"
    createBallerinaPlatform
    createBallerinaRuntime 
else
    if [ "$DISTRIBUTION" == "ballerina-platform" ]; then
        echo "Creating Ballerina Platform"
        createBallerinaPlatform
    elif [ "$DISTRIBUTION" == "ballerina-runtime" ]; then
        echo "Creating Ballerina Runtime"
        createBallerinaRuntime
    else
        echo "Error"
    fi
fi
