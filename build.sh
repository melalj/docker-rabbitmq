#!/bin/bash

set -e

app=rabbitmq
user=$app


# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)


echo "Creating user and group for $user ..."
useradd --home-dir ~ --create-home --shell /bin/bash --user-group $user


echo "Installing essentials ..."
apt-get update
apt-get install -y curl


echo "Installing erlang and $app repos ..."
apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 434975BD900CCBE4F7EE1B1ED208507CA14F4FCA
echo 'deb http://packages.erlang-solutions.com/debian jessie contrib' > /etc/apt/sources.list.d/erlang.list

apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 0A9AF2115F4687BD29803A206B73A36E6026DFCA
echo 'deb http://www.rabbitmq.com/debian testing main' > /etc/apt/sources.list.d/rabbitmq.list

apt-get update


echo "Installing $app ..."
apt_erlang_version=$(apt-cache show esl-erlang | grep ^Version | grep $ERLANG_VERSION | sort -n | head -1 | awk '{print $2}')
apt_rabbitmq_version=$(apt-cache show rabbitmq-server | grep ^Version | grep $RABBITMQ_VERSION | sort -n | head -1 | awk '{print $2}')
echo "erlang: $apt_erlang_version  rabbitmq: $apt_rabbitmq_version"

apt-get install -y \
    esl-erlang=$apt_erlang_version \
    rabbitmq-server=$apt_rabbitmq_version


echo "Adding $app environment to .bashrc ..."
tee /etc/profile.d/40-$app-env.sh <<'EOF'
if [ -d /usr/lib/rabbitmq/bin ]
then
    export PATH=/usr/lib/rabbitmq/bin:$PATH
fi
export RABBITMQ_LOGS=-
export RABBITMQ_SASL_LOGS=- 
export RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="-kernel inet_dist_listen_min 11500 inet_dist_listen_max 11999 $RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS"
EOF


echo "Cleaning up unnecessary files ..."
rm -rf \
    /usr/share/doc/rabbitmq-server \
    /etc/logrotate.d/rabbitmq-server \
    /lib/systemd/system/rabbitmq-server.service


echo "Setting permissions ..."
chown -R $user:$user ~ /etc/rabbitmq /var/lib/rabbitmq


echo "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
