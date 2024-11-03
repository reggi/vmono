#!/bin/bash

# Check parameters
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <name> <repository-urls...>"
  exit 1
fi

# Capture arguments
name="$1"
shift  # Shift all arguments to the left (original $1 gets lost)
repository_urls=("$@")

# Step 1: Create directory or exit if it exists
if [ -d "$name" ]; then
  echo "Directory $name already exists."
  exit 1
else
  mkdir "$name"
fi

# Change to the project directory
cd "$name"

# Step 2: Git and NPM initialization
git init
npm init -y

# Step 3: Add each repository as a submodule in "packages"
mkdir packages
for url in "${repository_urls[@]}"; do
  repo_name=$(basename "$url" .git)
  git submodule add "$url" "packages/$repo_name"
done

# Step 4: Modify package.json for NPM workspaces
jq '.workspaces = ["packages/*"]' package.json > temp.json && mv temp.json package.json

# Step 4.5: Create .gitignore file
echo "node_modules\n.DS_Store" > .gitignore

# Step 5: Create VSCode workspace file
cat << EOF > "$name.code-workspace"
{
  "folders": [
    { "path": ".", "name": "root" },
    $(for url in "${repository_urls[@]}"; do
      repo_name=$(basename "$url" .git)
      echo "    { \"path\": \"packages/$repo_name\" },"
    done)
  ]
}
EOF

jq '.scripts |= .+ {
  "_check-main": "git submodule foreach '\''if [ \\$(git symbolic-ref --short HEAD) != \"main\" ]; then echo \"\\$(basename \\$PWD) is not on main\"; exit 1; fi'\''",
  "_check-porcelain": "git submodule foreach '\''if [ -n \"\\$(git status --porcelain)\" ]; then echo \"\\$(basename \\$PWD) has uncommitted changes\"; exit 1; fi'\''",
  "_update-submodules": "git submodule foreach git pull origin main",
  "update": "npm run _check-main && npm run _check-porcelain",
}' package.json > temp.json && mv temp.json package.json

code "$name.code-workspace"

# Step 6: Run npm install at the root level
npm install

# Back to original directory
cd ..

echo "Setup complete."
