#!/bin/bash

NODE_VERSION=
die() {
        printf '%s\n' "$1" >&2
        exit 1
}
while :; do
        case $1 in
                -n|--node)
                        if [ "$2" ]; then
                                NODE_VERSION=$2
                                shift
                        else
                                die 'ERROR: "--node" requires a version argument'
                        fi
                        ;;
                --node=?*)
                        NODE_VERSION=${1#*=} # Delete everything up to "=" and assign the remainder.
                        ;;
                --node=) # Handle the case of an empty --file=
                        die 'ERROR: "--node" requires a version argument'
                        ;;
                --) # End of all options.
                        shift
                        break
                        ;;
                -?*) 
                        printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
                        ;;
                *) # Default case: No more options, so break out of the loop.
                        break
        esac

        shift
done

if [ -z "$NODE_VERSION" ]; then
        die 'ERROR: "--node" argument is required'
else
        # verify this version of node is installed
        npm -v
        ret_code=$?
        if [ $ret_code -ne 0 ]; then
                die 'ERROR: "npm" is not installed!'
        fi
        node_ver=$(node -v)
        ret_code=$?
        if [ $ret_code -ne 0 ] || [ $node_ver != "v$NODE_VERSION"* ]; then
                die "ERROR: node v$NODE_VERSION is not installed!" 
        fi
        printf 'Building Sharp Lambda Layer for use with NodeJS v%s\n' "$NODE_VERSION"
fi
exit

ARTIFACTS_DIR=$HOME/lambda_layer
mkdir -p $ARTIFACTS_DIR

cd $HOME
if [ -d "$HOME/sharp-custom-lambda-layer" ]; then
        # git pull
        echo 'Pulling latest changes from repository'
        cd $HOME/sharp-custom-lambda-layer
        /usr/bin/git pull
        cd $HOME
else
        # git clone
        echo 'Cloning repository'
        /usr/bin/git clone https://github.com/byrst/sharp-custom-lambda-layer.git
fi

sudo rm -rf $HOME/build
mkdir -p $HOME/build
cd $HOME/build
sudo /usr/bin/make -f $HOME/sharp-custom-lambda-layer/layer/Makefile ARTIFACTS_DIR=$ARTIFACTS_DIR

# create the Lambda Layer ZIP
echo 'Packaging Lambda Layer ZIP file'
cd $ARTIFACTS_DIR
/usr/bin/zip -r sharp-custom-lambda-layer.zip nodejs/ lib/

# Publish the Lambda Layer
echo 'Publishing Lambda Layer to AWS'
/usr/bin/aws lambda publish-layer-version --layer-name sharp-custom --description "Sharp Custom Image Layer" --zip-file fileb://sharp-custom-lambda-layer.zip --compatible-runtimes nodejs$NODE_VERSION.x --compatible-architectures "arm64"
