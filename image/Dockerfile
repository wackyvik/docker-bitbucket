FROM ingensi/oracle-jdk:latest
MAINTAINER Viktor Larionov <larionov@viktor.ee>

VOLUME [ "/var/atlassian/bitbucket" ]

# Install required utilities.
RUN /usr/bin/yum install -y gzip   && \
    /usr/bin/yum install -y tar    && \
    /usr/bin/yum install -y bzip2  && \
    /usr/bin/yum install -y git

# Import certificates to JVM truststore.
ADD support-files/install.certificates /var/tmp/install.certificates
RUN for certificate_url in $(/bin/cat /var/tmp/install.certificates); do                                                   \
        certificate=/var/tmp/$(/bin/basename ${certificate_url});                                                          \
        /usr/bin/wget --progress=bar:force ${certificate_url} -O ${certificate};                                           \
        alias=$(/bin/basename ${certificate} | /bin/sed s/'\.pem'/''/g | /bin/sed s/'\.crt'/''/g);                         \
        /usr/java/default/bin/keytool -importcert -trustcacerts -file ${certificate} -alias ${alias} -keystore /etc/pki/ca-trust/extracted/java/cacerts -storepass changeit -storetype JKS -noprompt; \
        /usr/java/default/bin/keytool -importcert -trustcacerts -file ${certificate} -alias ${alias} -keystore /usr/java/default/jre/lib/security/cacerts -storepass changeit -storetype JKS -noprompt; \
        /bin/rm -f ${certificate};                                                                                         \
    done                                                                                                                && \
    /bin/rm -f /var/tmp/install.certificates

# Prepare the directory layout.
RUN /bin/mkdir -p /usr/local/atlassian/bitbucket && \
    /bin/mkdir -p /var/atlassian/bitbucket

# Creating user and group.
RUN /sbin/groupadd -g 9996 bitbucket                                                                                    && \
    /sbin/useradd -u 9996 -d /usr/local/atlassian/bitbucket -c "Atlassian Bitbucket" -g bitbucket -M -s /bin/bash bitbucket

# Install Bitbucket binaries from package.
ADD support-files/BITBUCKET.VERSION /usr/local/atlassian/bitbucket/BITBUCKET.VERSION
RUN VERSION=$(/bin/cat /usr/local/atlassian/bitbucket/BITBUCKET.VERSION)                                       && \
    /usr/bin/wget --progress=bar:force https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-${VERSION}.tar.gz -O /var/tmp/atlassian-bitbucket-${VERSION}.tar.gz && \
    cd /var/tmp                                                                                                && \
    /usr/bin/tar -xvzf /var/tmp/atlassian-bitbucket-${VERSION}.tar.gz                                          && \
    /bin/cp -rfa /var/tmp/atlassian-bitbucket-${VERSION}/atlassian-bitbucket /usr/local/atlassian/bitbucket/   && \
    /bin/cp -rfa /var/tmp/atlassian-bitbucket-${VERSION}/bin /usr/local/atlassian/bitbucket/                   && \
    /bin/cp -rfa /var/tmp/atlassian-bitbucket-${VERSION}/conf /usr/local/atlassian/bitbucket/                  && \
    /bin/cp -rfa /var/tmp/atlassian-bitbucket-${VERSION}/lib /usr/local/atlassian/bitbucket/                   && \
    /bin/cp -rfa /var/tmp/atlassian-bitbucket-${VERSION}/webapps /usr/local/atlassian/bitbucket/               && \
    /bin/cp -rfa /var/tmp/atlassian-bitbucket-${VERSION}/work /usr/local/atlassian/bitbucket/                  && \
    /bin/rm -rf /var/tmp/atlassian-bitbucket-${VERSION}                                                        && \
    /bin/rm -rf /var/tmp/atlassian-bitbucket-${VERSION}.tar.gz

# Install Bitbucket RC scripts.
ADD support-files/install.hosts /etc/hosts.install
ADD support-files/bitbucket-init.sh /sbin/bitbucket-init.sh

# Create symlinks for correct layout.
RUN /bin/ln -s /var/tmp /usr/local/atlassian/bitbucket/temp                         && \
    /bin/ln -s /var/atlassian/bitbucket/logs /usr/local/atlassian/bitbucket/logs   && \
    /bin/ln -s /var/atlassian/bitbucket/logs /var/atlassian/bitbucket/log

# Install configuration overlay.
ADD conf-overlay/logging.properties /usr/local/atlassian/bitbucket/conf/
ADD conf-overlay/setenv.sh /usr/local/atlassian/bitbucket/bin/setenv.sh.template
ADD conf-overlay/server.xml /usr/local/atlassian/bitbucket/conf/server.xml.template

# ENTRYPOINT
RUN /bin/chown root:root /sbin/bitbucket-init.sh && \
    /bin/chmod 755 /sbin/bitbucket-init.sh
CMD /sbin/bitbucket-init.sh

# Expose default ports for Bitbucket.
EXPOSE 7990
