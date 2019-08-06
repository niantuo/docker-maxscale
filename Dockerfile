FROM centos:7
MAINTAINER 976056042@qq.com

# Setup for Galera Service (GS), not for Master-Slave environments

# We set some defaults for config creation. Can be overwritten at runtime.
ENV MAXSCALE_VERSION 2.1.16
ENV MAXSCALE_URL https://downloads.mariadb.com/enterprise/yzsw-dthq/mariadb-maxscale/2.0.1/rhel/7/x86_64/maxscale-2.0.1-1.rhel.7.x86_64.rpm
ENV MAX_THREADS=4 \
    MAX_USER="maxscale" \
    MAX_PASS="maxscalepass" \
    ENABLE_ROOT_USER=0 \ 
    SPLITTER_PORT=3306 \
    ROUTER_PORT=3307 \
    CLI_PORT=6603 \
    CONNECTION_TIMEOUT=600 \
    PERSIST_POOLMAX=0 \
    PERSIST_MAXTIME=3600 \
    BACKEND_SERVER_LIST="server1 server2 server3" \
    BACKEND_SERVER_PORT="3306" \
    USE_SQL_VARIABLES_IN="all"


RUN curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --skip-server --skip-tools \
    && yum -y update \
    && yum deplist maxscale | grep provider | awk '{print $2}' | sort | uniq | grep -v maxscale | sed ':a;N;$!ba;s/\n/ /g' | xargs yum -y install \
    && rpm -Uvh ${MAXSCALE_URL} \
    && yum clean all \
    && rm -rf /tmp/*

# Move configuration file in directory for exports and enable maxadmin cli
RUN mkdir -p /etc/maxscale.d \
    && cp /etc/maxscale.cnf.template /etc/maxscale.d/maxscale.cnf \
    && ln -sf /etc/maxscale.d/maxscale.cnf /etc/maxscale.cnf \
    && chown root:maxscale /etc/maxscale.d/maxscale.cnf \
    && chmod g+w /etc/maxscale.d/maxscale.cnf \
    && echo '[{"name": "root", "account": "admin", "password": ""}, {"name": "maxscale", "account": "admin", "password": ""}]' > /var/lib/maxscale/maxadmin-users
     

# VOLUME for custom configuration
VOLUME ["/etc/maxscale.d"] 

USER maxscale              
                    
# We copy our config creator script to the container
COPY docker-entrypoint.sh /
COPY reload.sh /usr/local/bin/
COPY list.sh /usr/local/bin/
# We expose our set Listener Ports
EXPOSE $SPLITTER_PORT $ROUTER_PORT $CLI_PORT

# We define the config creator as entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]

# We startup MaxScale as default command
CMD ["/usr/bin/maxscale","--nodaemon"]
