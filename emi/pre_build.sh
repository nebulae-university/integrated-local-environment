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
nvm use 12.22.12

# Check if nvm correctly set the current Node.js version
nvm_node_path="$NVM_DIR/versions/node/v12.22.12/bin"
if [ ! -d "$nvm_node_path" ]; then
    echo "Error: nvm did not properly set Node.js v12.22.12"
    exit 1
fi

node -v
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
mkdir -p $script_dir/merged-projects/frontend/emi
mkdir -p $script_dir/merged-projects/etc/
mkdir -p $script_dir/merged-projects/playground/


echo "===== Copying µFrontEnds ======"
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
    echo "Copying µFrontEnds from $dir"
    cp -R $dir/frontend/emi/* $script_dir/merged-projects/frontend/emi/ 
    cp  $dir/etc/mfe-setup.json $script_dir/merged-projects/etc/mfe-setup_$msname.json
done


echo "===== Merging /etc setup files ======"

# Create a new JSON file called mfe-setup.json with the merged array
jq -c '.[]' $script_dir/merged-projects/etc/*.json | jq -s > "$script_dir/merged-projects/etc/mfe-setup.json"
echo "MicroFrontEnd setups files merged at $script_dir/merged-projects/etc/mfe-setup.json"

echo "===== Composing EMI UI for Development ======"
cd $script_dir/merged-projects/playground
nebulae compose-ui development --shell-type=FUSE_REACT --shell-repo=https://github.com/nebulae-university/emi.git --frontend-id=emi --output-dir=emi  --setup-file=../etc/mfe-setup.json
cp -R ../frontend/emi/* emi/src/app/main
cd emi/
if [ "$(uname)" == "Linux" ]; then
    # For GNU sed (Linux)
    sed -i 's|localhost:3000|localhost:3005|g' .env.local
    sed -i 's|https://university.nebulae.com.co/auth|http://localhost:8080|g' .env
elif [ "$(uname)" == "Darwin" ]; then
    # For BSD sed (macOS)
    sed -i '' 's|localhost:3000|localhost:3005|g' .env.local
    sed -i '' 's|https://university.nebulae.com.co/auth|http://localhost:8080|g' .env
fi
mv .env.local .env.production

# force compatibility with newer keycloak
yarn add keycloak-js@18.0.1

npm run build 

echo "===== Removing local build service worker from EMI build ======"
rm build/service-worker.js

echo "===== UI Composition is Done ======"
echo "emi directory contents:"
ls .
