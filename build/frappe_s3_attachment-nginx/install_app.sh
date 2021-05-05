#!/bin/bash -xe

APP_NAME=${1}
APP_REPO=${2}
APP_BRANCH=${3}

[ "${APP_BRANCH}" ] && BRANCH="-b ${APP_BRANCH}"

mkdir -p /home/frappe/frappe-bench/sites/assets
cd /home/frappe/frappe-bench
echo -e "frappe\n${APP_NAME}" > /home/frappe/frappe-bench/sites/apps.txt
export  QT_QPA_PLATFORM=offscreen
npm install -g chalk rollup

mkdir -p apps
cd apps
git clone --depth 1 https://github.com/frappe/frappe ${BRANCH}
git clone --depth 1 ${APP_REPO} ${BRANCH} ${APP_NAME}

echo "Install frappe NodeJS dependencies . . ."
cd /home/frappe/frappe-bench/apps/frappe
yarn &
WAIT_YARN=$!
## solve stuck while installing yarn
while [[ $(ps -aux | grep ${WAIT_YARN} | grep -v grep | awk '{printf $2}') == ${WAIT_YARN} ]]; do echo "waiting for installation "; sleep $(( ( RANDOM % 10 ) + 1 )); done
echo "Install ${APP_NAME} NodeJS dependencies . . ."
cd /home/frappe/frappe-bench/apps/${APP_NAME}
yarn
echo "Build browser assets . . ."
cd /home/frappe/frappe-bench/apps/frappe
yarn production --app ${APP_NAME}
echo "Install frappe NodeJS production dependencies . . ."
cd /home/frappe/frappe-bench/apps/frappe
yarn install --production=true
echo "Install ${APP_NAME} NodeJS production dependencies . . ."
cd /home/frappe/frappe-bench/apps/${APP_NAME}
yarn install --production=true

mkdir -p /home/frappe/frappe-bench/sites/assets/${APP_NAME}

if [[ ${APP_NAME} == *"frappe_s3_attachment"* ]]; then
  cp -R /home/frappe/frappe-bench/apps/${APP_NAME}/${APP_NAME}/* /home/frappe/frappe-bench/sites/assets/${APP_NAME}
else
  cp -R /home/frappe/frappe-bench/apps/${APP_NAME}/${APP_NAME}/public/* /home/frappe/frappe-bench/sites/assets/${APP_NAME}
fi

# Add frappe and all the apps available under in frappe-bench here
echo "rsync -a --delete /var/www/html/assets/frappe /assets" > /rsync
echo "rsync -a --delete /var/www/html/assets/${APP_NAME} /assets" >> /rsync
chmod +x /rsync

rm /home/frappe/frappe-bench/sites/apps.txt