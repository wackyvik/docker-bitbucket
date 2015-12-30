#!/bin/bash

# Prerequisities and checks start.

# --- Add /etc/hosts records
if [ -f /etc/hosts.install ]; then
    /bin/cat /etc/hosts.install >>/etc/hosts
fi

# --- Fix file permissions.
/usr/bin/find /var/atlassian/bitbucket -type d -exec /bin/chmod 750 '{}' ';'
/usr/bin/find /var/atlassian/bitbucket -type f -exec /bin/chmod 640 '{}' ';'
/usr/bin/find /usr/local/atlassian/bitbucket -type d -exec /bin/chmod 750 '{}' ';' 
/usr/bin/find /usr/local/atlassian/bitbucket -type f -exec /bin/chmod 640 '{}' ';'
/bin/chmod 755 /var/atlassian
/bin/chmod 755 /usr/local/atlassian
/bin/chmod 750 /usr/local/atlassian/bitbucket/bin/*
/bin/chown root:root /var/atlassian
/bin/chown root:root /usr/local/atlassian
/bin/chown -R bitbucket:bitbucket /var/atlassian/bitbucket
/bin/chown -R bitbucket:bitbucket /usr/local/atlassian/bitbucket

# --- Clean up the logs.
if [ ! -d /var/atlassian/bitbucket/logs ]; then
    /bin/rm -f /var/atlassian/bitbucket/logs >/dev/null 2>&1
    /bin/mkdir /var/atlassian/bitbucket/logs
    /bin/chown bitbucket:bitbucket /var/atlassian/bitbucket/logs
    /bin/chmod 750 /var/atlassian/bitbucket/logs
fi

if [ ! -e /var/atlassian/bitbucket/log ]; then
    /bin/ln -s /var/atlassian/bitbucket/logs /var/atlassian/bitbucket/log
    /bin/chown -h bitbucket:bitbucket /var/atlassian/bitbucket/log
fi

cd /var/atlassian/bitbucket/logs

for logfile in $(/usr/bin/find /var/atlassian/bitbucket/logs -type f | /bin/grep -Eiv '\.gz$'); do
    /usr/bin/gzip ${logfile}
    /bin/mv ${logfile}.gz ${logfile}-$(/usr/bin/date +%d%m%Y-%H%M%S).gz
done

for logfile in $(/usr/bin/find /var/atlassian/bitbucket/logs -type f -mtime +7); do
    /bin/echo "Startup logfile ${logfile} is older than 7 days. Removing it."
    /bin/rm -f ${logfile}
done

# --- Prepare environment variables.
if [ -f /usr/local/atlassian/bitbucket/conf/server.xml.template ]; then
    export BITBUCKET_DB_DRIVER_ESCAPED=$(/bin/echo ${BITBUCKET_DB_DRIVER} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export BITBUCKET_DB_URL_ESCAPED=$(/bin/echo ${BITBUCKET_DB_URL} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export BITBUCKET_DB_USER_ESCAPED=$(/bin/echo ${BITBUCKET_DB_USER} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export BITBUCKET_DB_PASSWORD_ESCAPED=$(/bin/echo ${BITBUCKET_DB_PASSWORD} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export BITBUCKET_FE_NAME_ESCAPED=$(/bin/echo ${BITBUCKET_FE_NAME} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export BITBUCKET_FE_PORT_ESCAPED=$(/bin/echo ${BITBUCKET_FE_PORT} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export BITBUCKET_FE_PROTO_ESCAPED=$(/bin/echo ${BITBUCKET_FE_PROTO} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export CONFIGURE_FRONTEND_ESCAPED=$(/bin/echo ${CONFIGURE_FRONTEND} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g | sed -r s/'[ ]+'/''/g)
    export CONFIGURE_SQL_DATASOURCE_ESCAPED=$(/bin/echo ${CONFIGURE_SQL_DATASOURCE} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g | sed -r s/'[ ]+'/''/g)
    
    if [ "${CONFIGURE_FRONTEND_ESCAPED}" != "TRUE" -a "${CONFIGURE_FRONTEND_ESCAPED}" != "true" ]; then 
        /bin/sed -r s/'proxyName="[^"]+" proxyPort="[^"]+" scheme="[^"]+" '//g /usr/local/atlassian/bitbucket/conf/server.xml.template >/usr/local/atlassian/bitbucket/conf/server.xml.template.2
        /bin/mv /usr/local/atlassian/bitbucket/conf/server.xml.template.2 /usr/local/atlassian/bitbucket/conf/server.xml.template
    fi
    
    if [ "${CONFIGURE_SQL_DATASOURCE_ESCAPED}" != "TRUE" -a "${CONFIGURE_SQL_DATASOURCE_ESCAPED}" != "true" ]; then 
        /bin/sed -r s/'<Resource name="jdbc\/bitbucket"'/'<!-- <Resource name="jdbc\/bitbucket" '/g /usr/local/atlassian/bitbucket/conf/server.xml.template | /bin/sed -r s/'validationQuery="Select 1" \/>'/'validationQuery="Select 1" \/> -->'/g >/usr/local/atlassian/bitbucket/conf/server.xml.template.2
        /bin/mv /usr/local/atlassian/bitbucket/conf/server.xml.template.2 /usr/local/atlassian/bitbucket/conf/server.xml.template
    fi
    
    /bin/cat /usr/local/atlassian/bitbucket/conf/server.xml.template | /bin/sed s/'\%BITBUCKET_DB_DRIVER\%'/"${BITBUCKET_DB_DRIVER_ESCAPED}"/g      \
                                                                     | /bin/sed s/'\%BITBUCKET_DB_URL\%'/"${BITBUCKET_DB_URL_ESCAPED}"/g            \
                                                                     | /bin/sed s/'\%BITBUCKET_DB_USER\%'/"${BITBUCKET_DB_USER_ESCAPED}"/g          \
                                                                     | /bin/sed s/'\%BITBUCKET_DB_PASSWORD\%'/"${BITBUCKET_DB_PASSWORD_ESCAPED}"/g  \
                                                                     | /bin/sed s/'\%BITBUCKET_FE_NAME\%'/"${BITBUCKET_FE_NAME_ESCAPED}"/g          \
                                                                     | /bin/sed s/'\%BITBUCKET_FE_PORT\%'/"${BITBUCKET_FE_PORT_ESCAPED}"/g          \
                                                                     | /bin/sed s/'\%BITBUCKET_FE_PROTO\%'/"${BITBUCKET_FE_PROTO_ESCAPED}"/g        \
                                                                     >/usr/local/atlassian/bitbucket/conf/server.xml
    
    /bin/chown bitbucket:bitbucket /usr/local/atlassian/bitbucket/conf/server.xml
    /bin/chmod 640 /usr/local/atlassian/bitbucket/conf/server.xml
    /bin/rm -f /usr/local/atlassian/bitbucket/conf/server.xml.template
fi

if [ -f /usr/local/atlassian/bitbucket/bin/setenv.sh.template ]; then
    export JAVA_MEM_MAX_ESCAPED=$(/bin/echo ${JAVA_MEM_MAX} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export JAVA_MEM_MIN_ESCAPED=$(/bin/echo ${JAVA_MEM_MIN} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)

    /bin/cat /usr/local/atlassian/bitbucket/bin/setenv.sh.template | /bin/sed s/'\%JAVA_MEM_MIN\%'/"${JAVA_MEM_MIN_ESCAPED}"/g      \
                                                                   | /bin/sed s/'\%JAVA_MEM_MAX\%'/"${JAVA_MEM_MAX_ESCAPED}"/g      \
                                                                   >/usr/local/atlassian/bitbucket/bin/setenv.sh
    
    /bin/chown bitbucket:bitbucket /usr/local/atlassian/bitbucket/bin/setenv.sh
    /bin/chmod 750 /usr/local/atlassian/bitbucket/bin/setenv.sh
    /bin/rm -f /usr/local/atlassian/bitbucket/bin/setenv.sh.template
fi

# --- Prerequisities finished, all clear for takeoff.

# --- Environment variables.
export APP=bitbucket
export USER=bitbucket
export CONF_USER=bitbucket
export BASE=/usr/local/atlassian/bitbucket
export CATALINA_HOME="/usr/local/atlassian/bitbucket"
export CATALINA_BASE="/usr/local/atlassian/bitbucket"
export LANG=en_US.UTF-8
export BITBUCKET_HOME="/var/atlassian/bitbucket"

# --- Start Bitbucket
/usr/bin/su -m ${USER} -c "ulimit -n 63536 && cd $BASE && $BASE/bin/start-bitbucket.sh -fg"
