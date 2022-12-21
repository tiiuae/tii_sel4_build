#! /bin/bash

REPO_OVERRIDE= $1
MANIFEST_PATH=$2

PR_BR_NAME=$(echo $REPO_OVERRIDE | cut -d: -f2)
repo_owner=$(echo $REPO_OVERRIDE | cut -d: -f1)

curl  https://api.github.com/repos/tiiuae/${repo}/pulls?state=open -H "Accept: application/json" > api_file

 branch_name=$(jq -r '.[] | .head.ref' api_file)
        for name in ${branch_name[@]}; do 
            if [ "$PR_BR_NAME" = "$name" ]; then
                  pr_repo_owner=$( jq -r --arg PR_BR_NAME "$PR_BR_NAME" '.[] | select(.head.ref == $PR_BR_NAME) | .user.login' api_file )
                               
                  if [ $pr_repo_owner != $repo_owner ]; then 
                  sed -i "/<manifest>/a <remote name=\"$pr_repo_owner\" fetch=\"https://github.com/$pr_repo_owner\"/>" $MANIFEST_PATH
                  fi
                  sed -i "/$repo.git/c\<extend-project name=\"$repo_name.git\"                remote=\"$pr_repo_owner\" revision=\"$PR_BR_NAME\"/>" $MANIFEST_PATH

            fi
        done

cat $MANIFEST_PATH