#!/usr/bin/env bash
# This script setups dockerized Redash on Ubuntu 18.04.
set -eu

QL_BASE_PATH=/opt/ql/

install_docker() {
    # Install Docker
    if [[ -f /etc/lsb-release ]]; then
	sudo apt-get update
    	sudo apt-get -yy install apt-transport-https ca-certificates curl software-properties-common wget pwgen jsoncpp
    	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    	sudo apt-get update && sudo apt-get -y install docker-ce
    fi
    if [[ -f /etc/redhat-release ]]; then
 	sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate  docker-engine
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	sudo yum -y update
        sudo yum install -y yum-utils device-mapper-persistent-data lvm2 epel-release wget curl
	sudo yum install -y docker-ce pwgen
	sudo systemctl start docker
    fi
    # Install Docker Compose
    sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose
    sudo chmod +x /usr/bin/docker-compose

    # Allow current user to run Docker commands
    sudo usermod -aG docker $USER
}

clean_up() {
    echo $QL_BASE_PATH
    #Removing data dir as we don't want the data 
    if [[ -e /usr/bin/docker-compose && -e $QL_BASE_PATH/env ]]; then
    sudo docker-compose stop
    sudo docker-compose down
    sudo docker container stop $(sudo docker container ls -aq)
    sudo docker container rm $(sudo docker container ls -aq)
    sudo rm -rf $QL_BASE_PATH
    fi
}

create_directories() {
    if [[ ! -e $QL_BASE_PATH ]]; then
        sudo mkdir -p $QL_BASE_PATH
        sudo chown $USER:$USER $QL_BASE_PATH
    fi

    if [[ ! -e $QL_BASE_PATH/postgres-data ]]; then
        mkdir $QL_BASE_PATH/postgres-data
    fi
}

create_config() {
    if [[ -e $QL_BASE_PATH/env ]]; then
        rm $QL_BASE_PATH/env
        touch $QL_BASE_PATH/env
    fi

    COOKIE_SECRET=$(pwgen -1s 32)
    SECRET_KEY=$(pwgen -1s 32)
    POSTGRES_PASSWORD=$(pwgen -1s 32)
    QL_PASSWORD=$(pwgen -1s 8)
    REDASH_DATABASE_URL="postgresql://postgres:${POSTGRES_PASSWORD}@postgres/postgres"

    echo "PYTHONUNBUFFERED=0" >> $QL_BASE_PATH/env
    echo "REDASH_LOG_LEVEL=INFO" >> $QL_BASE_PATH/env
    echo "REDASH_REDIS_URL=redis://redis:6379/0" >> $QL_BASE_PATH/env
    echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> $QL_BASE_PATH/env
    echo "REDASH_COOKIE_SECRET=$COOKIE_SECRET" >> $QL_BASE_PATH/env
    echo "REDASH_SECRET_KEY=$SECRET_KEY" >> $QL_BASE_PATH/env
    echo "REDASH_DATABASE_URL=$REDASH_DATABASE_URL" >> $QL_BASE_PATH/env
}

setup_sql() {
    cp -rpf sql_scripts $QL_BASE_PATH/
    sed -ri  "s/PASSWORD ......../PASSWORD '$QL_PASSWORD'/"  $QL_BASE_PATH/sql_scripts/01_init-db.sh
}

setup_compose() {
    REQUESTED_CHANNEL=stable
    cp docker-compose.yml $QL_BASE_PATH/ ; cp postgres.conf $QL_BASE_PATH/ ; cp pg_hba.conf $QL_BASE_PATH/
    cd $QL_BASE_PATH
    echo "export COMPOSE_PROJECT_NAME=ql" >> ~/.profile
    echo "export COMPOSE_FILE=$QL_BASE_PATH/docker-compose.yml" >> ~/.profile
    sudo docker-compose run --rm server create_db
    sudo docker-compose up -d
    echo -e  "\e[32mFinished with the QL installation\e[0m"
    echo -e "\e[31mBefore continuing, please proceed and complete the setup in web interface\e[0m"
}

setup_datasource() {
    while true; do
	    read -p "Registered organisation ?[Y/n]" yn
	    case $yn in
	       	    [Yy]* ) read -p "Provide the registered organisation name:" orgname ; sudo docker exec  -it $(sudo docker ps -a | grep ql_server| awk '{print $1}') /app/bin/run /app/manage.py ds new "DummyData" --type  "pg" --org "$orgname" --options "{ \"dbname\" : \"bank\", \"host\": \"postgres\", \"user\": \"ql_user\", \"password\": \"$QL_PASSWORD\" }" > /dev/null 2>&1 ;echo -e "\e[32m Datasource configuration for dummy data completed\e[0m" ;sudo docker exec  -it $(sudo docker ps -a | grep ql_server| awk '{print $1}') /app/bin/run /app/manage.py ds new "Postgres" --type  "pg" --org "$orgname" --options "{ \"dbname\" : \"datasource\", \"host\": \"postgres\", \"user\": \"postgres\", \"password\": \"$POSTGRES_PASSWORD\" }" > /dev/null 2>&1 ;echo -e "\e[32mDatasource configuration for blank db completed\e[0m" ;  break;;
	            [Nn]* ) exit;;
	            * ) echo "Please answer yes or no.";;
	    esac
    done
}

clean_up
install_docker
create_directories
create_config
setup_sql
setup_compose
setup_datasource
