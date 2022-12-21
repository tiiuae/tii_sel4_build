#! /bin/bash

BRANCH_OVERRIDE=$1
MANIFEST_PATH=$2

sel4_repos=(global-components
            seL4
            seL4_tools
            util_libs
            camkes-vm-examples
            camkes-vm-linux
            camkes-vm
            camkes-vm-images
            seL4_projects_libs
            capdl )
PR_BR_NAME=$1

same_repocheck () {
      repo=$1  
      pr_repo_owner=$( jq -r --arg PR_BR_NAME "$PR_BR_NAME" '.[] | select(.head.ref == $PR_BR_NAME) | .user.login' api_file )
      repo_owner=$(jq -r --arg PR_BR_NAME "$PR_BR_NAME" '.[] | select(.head.ref == $PR_BR_NAME) | .base.user.login' api_file)
      repo_name=$(jq -r --arg PR_BR_NAME "$PR_BR_NAME" '.[] | select(.head.ref == $PR_BR_NAME) | .head.repo.name' api_file)
      if [ $pr_repo_owner != $repo_owner ]; then 
      sed -i "/<manifest>/a <remote name=\"$pr_repo_owner\" fetch=\"https://github.com/$pr_repo_owner\"/>" $MANIFEST_PATH
      fi
      sed -i "/$repo.git/c\<extend-project name=\"$repo_name.git\"                remote=\"$pr_repo_owner\" revision=\"$PR_BR_NAME\"/>" $MANIFEST_PATH
    }


for repo in ${sel4_repos[@]}; do 
curl  https://api.github.com/repos/tiiuae/${repo}/pulls?state=open -H "Accept: application/json" > api_file

 branch_name=$(jq -r '.[] | .head.ref' api_file)
        for name in ${branch_name[@]}; do 
            if [ "$PR_BR_NAME" = "$name" ]; then
            #same_branch+=($repo)
            same_repocheck $repo
            fi
        done
done

cat $MANIFEST_PATH