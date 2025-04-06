#!/bin/bash

cat <<"EOF"

_____                    __                                          _
|_   _|__ _ __ _ __ __ _ / _| ___  _ __ _ __ ___     __ _ _ __  _ __ | |_   _
  | |/ _ \ '__| '__/ _` | |_ / _ \| '__| '_ ` _ \   / _` | '_ \| '_ \| | | | |
  | |  __/ |  | | | (_| |  _| (_) | |  | | | | | | | (_| | |_) | |_) | | |_| |
  |_|\___|_|  |_|  \__,_|_|  \___/|_|  |_| |_| |_|  \__,_| .__/| .__/|_|\__, |
                                                         |_|   |_|      |___/
                          _   _                     _
  _____  _____  ___ _   _| |_(_) ___  _ __   __   _(_) __ _
 / _ \ \/ / _ \/ __| | | | __| |/ _ \| '_ \  \ \ / / |/ _` |
|  __/>  <  __/ (__| |_| | |_| | (_) | | | |  \ V /| | (_| |
 \___/_/\_\___|\___|\__,_|\__|_|\___/|_| |_|   \_/ |_|\__,_|

 ____  _          _ _   ____            _       _
/ ___|| |__   ___| | | / ___|  ___ _ __(_)_ __ | |_
\___ \| '_ \ / _ \ | | \___ \ / __| '__| | '_ \| __|
 ___) | | | |  __/ | |  ___) | (__| |  | | |_) | |_
|____/|_| |_|\___|_|_| |____/ \___|_|  |_| .__/ \__|
                                         |_|
EOF

set -x
echo -e "\e[1;32m ***** This script is executed at *****" $(date '+%Y-%m-%d %H:%M:%S')
sleep 2
echo " ******* Going to execute bash function *******"

function tfi(){
   echo "***** tfi - A basic terraform function *****"
   echo " **** Going to execute terraform apply command *****"
   terraform init
}
function tft(){
   echo "***** tfa - A basic terraform function *****"
   echo " **** Going to execute terraform apply command *****"
   terraform fmt
}
function tfv(){
   echo "***** tfa - A basic terraform function *****"
   echo " **** Going to execute terraform apply command *****"
   terraform validate
}
function tfa(){
   echo "***** tfa - A basic terraform function *****"
   echo " **** Going to execute terraform apply command *****"
   terraform apply --auto-approve
}
tfi
tft
tfv
tfa
exit 0 


