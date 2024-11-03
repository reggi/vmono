i want to make a tool in bash that does the following

tool <name> <repository-urls...>

1. create dir in cwd "name" if it already exists do nothing and throw 
2. git init the dir
3. npm init -y the dir
2. provide the script n number of repositories as arguments
3. for each repository url add them as submodules in "packages"
4. add packages/* to npm workspaces
5. create a vscode workspace file in "name" dir that has n projects for each repo dir in packages (and an extra one called "root"
6. run npm install at the root level