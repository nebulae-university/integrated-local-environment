#!/bin/bash

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
    echo "Sourced .bashrc"
fi
if [ -f ~/.zprofile ]; then
    source ~/.zprofile
    echo "Sourced .zprofile"
fi

echo "===== infering working directory  ======"
script_dir="$(dirname "$0")"
echo "The current file path is: $script_dir"

echo "===== Installing NebulaE CLI ======"
if command -v "nvm" >/dev/null 2>&1; then
    echo "nvm exists in the system."
else
    echo "nvm does not exist in the system. will import it"
    export NVM_DIR=$HOME/.nvm;
    source $NVM_DIR/nvm.sh;
fi


# Debug: Print the initial PATH for analysis
#echo "Initial PATH: $PATH"

# Ensure nvm is loaded
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Use Node.js version 10
nvm use 10.24.1

# Check if nvm correctly set the current Node.js version
nvm_node_path="$NVM_DIR/versions/node/v10.24.1/bin"
if [ ! -d "$nvm_node_path" ]; then
    echo "Error: nvm did not properly set Node.js v10.24.1"
    exit 1
fi

# Manually override PATH to prioritize nvm's Node.js binary without removing /opt/homebrew/bin
if [ "$(uname)" == "Darwin" ]; then
    export PATH="$nvm_node_path:/opt/homebrew/bin:$(echo $PATH | sed -e 's|/opt/homebrew/bin:||g')"
fi

# Debug: Print the updated PATH
#echo "Updated PATH: $PATH"

# Verify Node.js and npm versions
echo "Node.js binary: $(which node)"
echo "Node.js version: $(node -v)"
echo "npm version: $(npm -v)"
echo "which jq: $(which jq)"
echo "jq version: $(jq --version)"

if command -v "nebulae" >/dev/null 2>&1; then
    echo "@nebulae/cli exists in the system."
else
    echo "@nebulae/cli does not exist in the system. will install it"
    npm install -g @nebulae/cli@0.6.1
fi


echo "===== Removing previous build ======"
rm -rf $script_dir/merged-projects/

echo "===== Setting directories ======"
mkdir -p $script_dir/merged-projects/api/emi-gateway
mkdir -p $script_dir/merged-projects/api/emi-gateway/graphql
mkdir -p $script_dir/merged-projects/api/emi-gateway/rest
mkdir -p $script_dir/merged-projects/etc/
mkdir -p $script_dir/merged-projects/playground/

echo "===== Copying µAPIs ======"
# Create an empty array to store matching directories
microservices_directories=()
# Loop through all directories in the provided path
for directory in "$script_dir/../../"/*/; do
    # Extract the directory name
    dir_name=$(basename "$directory")    
    # Check if the directory name starts with 'ms-'
    if [[ "$dir_name" == ms-* ]]; then
        microservices_directories+=("$directory")
    fi
done
for dir in "${microservices_directories[@]}"; do    
    msname="$(basename -- $dir)"
    echo "Copying µAPIs from $dir"    
    cp -R $dir/api/emi-gateway/graphql/* $script_dir/merged-projects/api/emi-gateway/graphql
    cp  $dir/etc/mapi-setup.json $script_dir/merged-projects/etc/mapi-setup_$msname.json
done


echo "===== Merging /etc setup files ======"

# Create a new JSON file called mapi-setup.json with the merged array
jq -c '.[]' $script_dir/merged-projects/etc/*.json | jq -s > "$script_dir/merged-projects/etc/mapi-setup.json"
echo "MicroFrontEnd setups files merged at $script_dir/merged-projects/etc/mapi-setup.json"

echo "===== Composing EMI-GATEWAY API for Development ======"
cd $script_dir/merged-projects/playground
nebulae compose-api development --api-type=NEBULAE_GATEWAY --api-repo=https://github.com/nebulae-university/emi-gateway.git --api-id=emi-gateway --output-dir=emi-gateway  --setup-file=../etc/mapi-setup.json
cp -R ../api/emi-gateway/graphql/* emi-gateway/graphql/
cd emi-gateway/

echo "===== API Composition is Done ======"
echo "emi-gateway directory contents:"
ls .
