source $HOME/.bashrc
WORKING_DIR=$(pwd)
echo WORKING_DIR
# temporarily switch to the JavaScript dir so we can run npm commands
cd $SRCROOT"/Javascript"
echo WORKING_DIR
# build the JavaScript bundle
npm run build
# if non-zero exit code, exit and warn the user
if [ $? -ne 0 ]; then
        echo "failure in 'Run Script' phase - building JS bundle"
        cd $WORKING_DIR
        exit 1
fi
# go back to the working directory
cd $WORKING_DIR
