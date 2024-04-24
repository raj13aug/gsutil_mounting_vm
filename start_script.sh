#!/bin/bash
export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s` echo "deb https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update -y && sudo apt-get install gcsfuse -y
mkdir /home/gcp/gcs-bucket  // create mount path for our bucket
sudo chown -R 777 /home/gcp/gcs-bucket
sudo gcsfuse -o allow_other -file-mode=777 -dir-mode=777 model-artifact-bucket /home/gcp/gcs-bucket