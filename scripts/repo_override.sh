#! /bin/bash

REPO_OVERRIDE=$1
MANIFEST_PATH=$2
REVISION=$(echo $REPO_OVERRIDE | cut -d: -f2)
OWNER=$(echo $REPO_OVERRIDE | cut -d: -f1 | cut -d/ -f1)
REPO=$(echo $REPO_OVERRIDE | cut -d: -f1 | cut -d/ -f2)

if [ -n "$REPO" ] && [ -n "$REVISION" ]; then
      if [ $OWNER != "tiiuae" ] && [ ! grep -q "remote name=\"$OWNER\"" $MANIFEST_PATH]; then 
      sed -i "/<manifest>/a <remote name=\"$OWNER\" fetch=\"https://github.com/$OWNER\"/>" $MANIFEST_PATH
      fi
      sed -i "/$REPO.git/c\  <extend-project name=\"$REPO.git\"            remote=\"$OWNER\" revision=\"$REVISION\"/>" $MANIFEST_PATH
fi

cat $MANIFEST_PATH