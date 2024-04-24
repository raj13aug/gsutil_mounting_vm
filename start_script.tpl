#!/bin/bash
export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /usr/share/keyrings/cloud.google.asc
sudo apt-get update -y
sudo apt-get install gcsfuse -y
mkdir -p /home/gcs-bucket  
sudo chown -R 777 /home/gcs-bucket
sudo gcsfuse -o allow_other -file-mode=777 -dir-mode=777 '{$bucket_name}' /home/gcs-bucket
sudo touch /home/gcs-bucket/cloudroot7.txt