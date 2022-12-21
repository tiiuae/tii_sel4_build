#! /bin/bash

BRANCH_OVERRIDE=$1
MANIFEST_PATH=$2
echo "In branch override file"
# wget https://raw.githubusercontent.com/tiiuae/tii_sel4_manifest/tii/development/external.xml
# REPOS=$(grep -oP 'extend-project name="\K[^"]+' $MANIFEST_PATH)

# for REPO in ${REPOS[@]}; do
  # REVISION=$(git ls-remote https://github.com/amalx-ssrc/${REPO} ${BRANCH_OVERRIDE})

# J=repo forall -c "git remote -v" | awk '{print $1}' | uniq

REPOS=$(grep -oP 'extend-project name="\K[^"]+' $MANIFEST_PATH)

for REPO in ${REPOS[@]}; do
  REVISION=$(git ls-remote https://github.com/tiiuae/${REPO} ${BRANCH_OVERRIDE})
  if [ -n "$REPO" ] && [ -n "$REVISION" ]; then
     sed -i "/$REPO/c\  <extend-project name=\"$REPO\"            remote=\"tiiuae\" revision=\"$BRANCH_OVERRIDE\"/>" $MANIFEST_PATH
    fi
done
cat $MANIFEST_PATH



# REPOS=$(repo forall -c "git remote -v" | awk '{print  $1","$2}' | uniq)

# echo "REPOS are printing $REPOS"
#   for REPO in ${REPOS[@]}
#   do 
#     REMOTE=$(echo $REPO | cut -d, -f1)
#     URL=$(echo $REPO | cut -d, -f2)
#     REVISION=$(git ls-remote $URL $BRANCH_OVERRIDE)
#     PROJECT=$(echo $URL | awk -F/ '{print $NF}')

#     echo "values"
#     echo "REMOTE" $REMOTE
#     echo "URL" $URL
#     echo "REVISION" $REVISION
#     echo "PROJECT" $PROJECT



#     if [ -n "$PROJECT" ] && [ -n "$REVISION" ]; then
#      sed -i "/$PROJECT/c\  <extend-project name=\"$PROJECT\"            remote=\"$REMOTE\" revision=\"$BRANCH_OVERRIDE\"/>" $MANIFEST_PATH
#     fi
#   done

cat $MANIFEST_PATH

