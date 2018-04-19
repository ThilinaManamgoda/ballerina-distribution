#!/bin/bash

function printUsage() {
    echo "Usage:"
    echo "$0 [options]"
    echo "options:"
    echo "    -v (--version)"
    echo "        version of the ballerina distribution"
    echo "    -p (--path)"
    echo "        path of the ballerina distributions"
    echo "    -d (--dist)"
    echo "        ballerina distribution type either of the followings"
    echo "        If not specified both distributions will be built"
    echo "        1. ballerina-platform"
    echo "        2. ballerina-runtime"
    echo "eg: $0 -v 1.0.0 -p /home/username/Packs"
    echo "eg: $0 -v 1.0.0 -p /home/username/Packs -d ballerina-platform"
}

BUILD_ALL_DISTRIBUTIONS=false
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case ${key} in
    -v|--version)
    BALLERINA_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--path)
    DIST_PATH="$2"
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

if [ -z "$BALLERINA_VERSION" ]; then
    echo "Please enter the version of the ballerina pack"
    printUsage
    exit 1
fi

if [ -z "$DIST_PATH" ]; then
    echo "Please enter the path of the ballerina packs"
    printUsage
    exit 1
fi

if [ -z "$DISTRIBUTION" ]; then
    BUILD_ALL_DISTRIBUTIONS=true
fi




BALLERINA_DISTRIBUTION_LOCATION=${DIST_PATH}
BALLERINA_PLATFORM=ballerina-platform-linux-${BALLERINA_VERSION}
BALLERINA_RUNTIME=ballerina-runtime-linux-${BALLERINA_VERSION}
BALLERINA_INSTALL_DIRECTORY=ballerina-${BALLERINA_VERSION}
PLATFORM_SPEC_FILE="rpmbuild/SPECS/ballerina_platform.spec"
RUNTIME_SPEC_FILE="rpmbuild/SPECS/ballerina_runtime.spec"
RPM_BALLERINA_VERSION=$(echo "${BALLERINA_VERSION//-/.}")

echo "Build started at" $(date +"%Y-%m-%d %H:%M:%S")





function extractPack() {
    echo "Extracting the ballerina distribution, " $1
    rm -rf rpmbuild/SOURCES
    mkdir -p rpmbuild/SOURCES
    unzip $1 -d rpmbuild/SOURCES/ > /dev/null 2>&1
}

# Set variables in SPEC file
# Globals:
#   BALLERINA_VERSION
#   RPM_BALLERINA_VERSION
#   RUNTIME_SPEC_FILE
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
#   PLATFORM_SPEC_FILE
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

# Create Ballerina Platform RPM
# Globals:
#   BALLERINA_DISTRIBUTION_LOCATION
#   BALLERINA_PLATFORM
#   PLATFORM_SPEC_FILE
# Arguments:
# Returns:
#   None
function createBallerinaPlatform() {
    echo "Creating ballerina platform installer"
    extractPack "$BALLERINA_DISTRIBUTION_LOCATION/$BALLERINA_PLATFORM.zip"
    setupVersion_platform
    rpmbuild -bb --define "_topdir  $(pwd)/rpmbuild" ${PLATFORM_SPEC_FILE}

}

# Create Ballerina Runtime RPM
# Globals:
#   BALLERINA_DISTRIBUTION_LOCATION
#   BALLERINA_PLATFORM
#   RUNTIME_SPEC_FILE
# Arguments:
# Returns:
#   None
function createBallerinaRuntime() {
    echo "Creating ballerina runtime installer"
    extractPack "$BALLERINA_DISTRIBUTION_LOCATION/$BALLERINA_RUNTIME.zip"
    setupVersion_runtime
    rpmbuild -bb --define "_topdir  $(pwd)/rpmbuild" ${RUNTIME_SPEC_FILE}
}


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

echo "Build completed at" $(date +"%Y-%m-%d %H:%M:%S")
