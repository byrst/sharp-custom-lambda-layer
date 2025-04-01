#!/bin/bash

HOME_DIR=/home/ec2-user
ARTIFACTS_DIR=$HOME_DIR/lambda_layer

cd $HOME_DIR
if [ -d "$HOME_DIR/sharp-custom-lambda-layer" ]; then
	# git pull
	echo 'Pulling latest changes from repository'
	cd $HOME_DIR/sharp-custom-lambda-layer
	/usr/bin/git pull
	cd $HOME_DIR
else
	# git clone
	echo 'Cloning repository'
	/usr/bin/git clone https://github.com/byrst/sharp-custom-lambda-layer.git
fi

sudo rm -rf $HOME_DIR/build
mkdir $HOME_DIR/build
cd $HOME_DIR/build
sudo /usr/bin/make -f $HOME_DIR/sharp-custom-lambda-layer/layer/Makefile

# create the Lambda Layer ZIP
echo 'Packaging Lambda Layer ZIP file'
cd $ARTIFACTS_DIR
/usr/bin/zip -r sharp-custom-lambda-layer.zip nodejs/ lib/

# Publish the Lambda Layer
echo 'Publishing Lambda Layer to AWS'
#/usr/bin/aws lambda publish-layer-version --layer-name sharp-custom --description "Sharp Custom Image Layer" --zip-file fileb://sharp-custom-lambda-layer.zip --compatible-runtimes nodejs20.x nodejs22.x --compatible-architectures "arm64"
