REPO_OVERRIDE=$1
BRANCH_OVERRIDE=$2
MANIFEST_PATH=$3


REVISION=$(echo $REPO_OVERRIDE | cut -d: -f2)
OWNER=$(echo $REPO_OVERRIDE | cut -d: -f1 | cut -d/ -f1)
REPOSITORY=$(echo $REPO_OVERRIDE | cut -d: -f1 | cut -d/ -f2)

repo_override (){

if [ -n "$REPOSITORY" ] && [ -n "$REVISION" ]; then
      if [ $OWNER != "tiiuae" ] && [ "$(! grep -q "remote name=\"$OWNER\"" $MANIFEST_PATH)" ]; then 
      sed -i "/<manifest>/a <remote name=\"$OWNER\" fetch=\"https://github.com/$OWNER\"/>" $MANIFEST_PATH
      fi
      sed -i "/$REPOSITORY.git/c\  <extend-project name=\"$REPOSITORY.git\"            remote=\"$OWNER\" revision=\"$REVISION\"/>" $MANIFEST_PATH
fi

}

branch_override () {
   REPOS=$(grep -oP 'extend-project name="\K[^"]+' $MANIFEST_PATH)

for REPO in ${REPOS[@]}; do
  REVISION=$(git ls-remote https://github.com/amalx-ssrc/${REPO} ${BRANCH_OVERRIDE})
  if [ -n "$REPO" ] && [ -n "$REVISION" ] && [  "$REPO" != "${REPOSITORY}.git" ]; then
     sed -i "/$REPO/c\  <extend-project name=\"$REPO\"            remote=\"amalx-ssrc\" revision=\"$BRANCH_OVERRIDE\"/>" $MANIFEST_PATH
    fi
done
}

if [ -n $REPO_OVERRIDE ]; then
   repo_override
fi

if [ -n $BRANCH_OVERRIDE ]; then 
   branch_override
fi 



cat $MANIFEST_PATH
