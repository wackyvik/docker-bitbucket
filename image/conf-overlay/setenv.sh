#!/usr/bin/env bash
#
# One way to set the BITBUCKET_HOME path is here via this variable.  Simply uncomment it and set a valid path like
# /bitbucket/home.  You can of course set it outside in the command terminal; that will also work.
#

if [ "x${BITBUCKET_HOME}" = "x" ]; then
    export BITBUCKET_HOME=
fi

# When upgrading from the packaged distribution BITBUCKET_HOME may not be set. Fallback to legacy STASH_HOME
# and output a message for the user recommending that they update their environment
if [ "x${BITBUCKET_HOME}" = "x" ]; then
    if [ ! "x${STASH_HOME}" = "x" ]; then
        BITBUCKET_HOME=${STASH_HOME}
        echo ""
        echo "--------------------------------------------------------------------------------------"
        echo "  WARNING: STASH_HOME has been deprecated and replaced with BITBUCKET_HOME."
        echo "  We recommend you set BITBUCKET_HOME instead of STASH_HOME."
        echo "  Future versions of Bitbucket may not support the STASH_HOME variable."
        echo "--------------------------------------------------------------------------------------"
    fi
fi

if [ "x${JAVA_HOME}" = "x" ]; then
    export JAVA_HOME=
fi

#
# Native libraries, such as the Tomcat native library, can be placed here for use by Bitbucket. Alternatively, native
# libraries can also be placed in $BITBUCKET_HOME/lib/native, where they will also be included in the library path used
# by the JVM. By placing libraries in $BITBUCKET_HOME, they can be preserved across Bitbucket upgrades.
#
# NOTE: You must choose the library architecture, x86 or x64, based on the JVM you'll be running, _not_ based on the OS.
#
JVM_LIBRARY_PATH="$CATALINA_HOME/lib/native:$BITBUCKET_HOME/lib/native"

#
# Occasionally Atlassian Support may recommend that you set some specific JVM arguments.  You can use this variable
# below to do that.
#
JVM_SUPPORT_RECOMMENDED_ARGS=""

#
# The following 2 settings control the minimum and maximum given to the Atlassian Bitbucket Java virtual machine.
# In larger Bitbucket instances, the maximum amount will need to be increased.
#
JVM_MINIMUM_MEMORY="%JAVA_MEM_MIN%"
JVM_MAXIMUM_MEMORY="%JAVA_MEM_MAX%"

#
# File encoding passed into the Atlassian Bitbucket Java virtual machine
#
JVM_FILE_ENCODING="UTF-8"

#
# The following are the required arguments needed for Atlassian Bitbucket.
#
JVM_REQUIRED_ARGS="-Djava.awt.headless=true -Dfile.encoding=${JVM_FILE_ENCODING} -Datlassian.standalone=BITBUCKET -Dorg.apache.jasper.runtime.BodyContentImpl.LIMIT_BUFFER=true -Dmail.mime.decodeparameters=true -Dorg.apache.catalina.connector.Response.ENFORCE_ENCODING_IN_GET_WRITER=false"

#
# Uncommenting the following will set the umask for the Atlassian Bitbucket application. If can be used to override
# the default settings of the Bitbucket user is they are not sufficiently secure.
#
# umask 0027

#-----------------------------------------------------------------------------------
# JMX
#
# JMX is enabled by selecting an authentication method value for JMX_REMOTE_AUTH and then configuring related the
# variables.
#
# See http://docs.oracle.com/javase/7/docs/technotes/guides/management/agent.html for more information on JMX
# configuration in general.
#-----------------------------------------------------------------------------------

#
# Set the authentication to use for remote JMX access. Anything other than "password" or "ssl" will cause remote JMX
# access to be disabled.
#
JMX_REMOTE_AUTH=

#
# The port for remote JMX support if enabled
#
JMX_REMOTE_PORT=3333

#
# If `hostname -i` returns a local address then JMX-RMI communication may fail because the address returned by JMX for
# the RMI-JMX stub will not resolve for non-local clients. To fix this you will need to explicitly specify the
# IP address / host name of this server that is reachable / resolvable by JMX clients. e.g.
# RMI_SERVER_HOSTNAME="-Djava.rmi.server.hostname=non.local.name.of.my.bitbucket.server"
#
#RMI_SERVER_HOSTNAME="-Djava.rmi.server.hostname="

#-----------------------------------------------------------------------------------
# JMX username/password support
#-----------------------------------------------------------------------------------

#
# The full path to the JMX username/password file used to authenticate remote JMX clients
#
#JMX_PASSWORD_FILE=

#-----------------------------------------------------------------------------------
# JMX SSL support
#-----------------------------------------------------------------------------------

#
# The full path to the Java keystore which must contain Bitbucket's key pair used for SSL authentication for JMX
#
#JAVA_KEYSTORE=

#
# The password for JAVA_KEYSTORE
#
#JAVA_KEYSTORE_PASSWORD=

#
# The full path to the Java truststore which must contain the client certificates accepted by Bitbucket for SSL authentication
# of JMX
#
#JAVA_TRUSTSTORE=

#
# The password for JAVA_TRUSTSTORE
#
#JAVA_TRUSTSTORE_PASSWORD=

#-----------------------------------------------------------------------------------
#
# In general don't make changes below here
#
#-----------------------------------------------------------------------------------

PRGDIR=`dirname "$0"`

if [ -z "$BITBUCKET_HOME" ]; then
    echo ""
    echo "--------------------------------------------------------------------------------------"
    echo "  Bitbucket doesn't know where to store its data. Please configure the BITBUCKET_HOME"
    echo "  environment variable with the directory where Bitbucket should store its data."
    echo "  Ensure that the path to BITBUCKET_HOME does not contain spaces. BITBUCKET_HOME may"
    echo "  be configured in setenv.sh, if preferred, rather than exporting it as an"
    echo "  environment variable."
    echo "--------------------------------------------------------------------------------------"
    exit 1
fi

echo $BITBUCKET_HOME | grep -q " "
if [ $? -eq 0 ]; then
    echo ""
    echo "-------------------------------------------------------------------------------"
    echo "  BITBUCKET_HOME \"$BITBUCKET_HOME\" contains spaces."
    echo "  Using a directory with spaces is likely to cause unexpected behaviour and is"
    echo "  not supported. Please use a directory which does not contain spaces."
    echo "-------------------------------------------------------------------------------"
    exit 1
fi

UMASK=`umask`
UMASK_SYMBOLIC=`umask -S`
if echo $UMASK | grep -qv '0[2367]7$'; then
    FORCE_EXIT=false
    echo ""
    echo "----------------------------------------------------------------------------------"
    echo "Bitbucket is being run with a umask that contains potentially unsafe settings."
    echo "The following issues were found with the mask \"$UMASK_SYMBOLIC\" ($UMASK):"
    if echo $UMASK | grep -qv '7$'; then
        echo " - access is allowed to 'others'. It is recommended that 'others' be denied"
        echo "   all access for security reasons."
    fi
    if echo $UMASK | grep -qv '[2367][0-9]$'; then
        echo " - write access is allowed to 'group'. It is recommend that 'group' be"
        echo "   denied write access. Read access to a restricted group is recommended"
        echo "   to allow access to the logs."
    fi
    if echo $UMASK | grep -qv '0[0-9][0-9]$'; then
        echo " - full access has been denied to 'user'. Bitbucket cannot be run without full"
        echo "   access being allowed."
        FORCE_EXIT=true
    fi
    echo ""
    echo "The recommended umask for Bitbucket is \"u=,g=w,o=rwx\" (0027) and can be"
    echo "configured in setenv.sh"
    echo "----------------------------------------------------------------------------------"
    if [ "x${FORCE_EXIT}" = "xtrue" ]; then
        exit 1;
    fi
fi

if [ "x$JMX_REMOTE_AUTH" = "xpassword" ]; then
    if [ -z "$JMX_REMOTE_PORT" ]; then
        echo ""
        echo "-------------------------------------------------------------------------------"
        echo "  Remote JMX is enabled.                                                       "
        echo "                                                                               "
        echo "  You must specify a valid port number. This is done by specifying             "
        echo "  JMX_REMOTE_PORT in setenv.sh.                                                "
        echo "-------------------------------------------------------------------------------"
        exit 1
    fi

    if [ -z "$JMX_PASSWORD_FILE" ] || [ ! -f "$JMX_PASSWORD_FILE" ]; then
        echo ""
        echo "-------------------------------------------------------------------------------"
        echo "  Remote JMX with username/password authentication is enabled.                 "
        echo "                                                                               "
        echo "  You must specify a valid path to the password file used by Bitbucket.        "
        echo "  This is done by specifying JMX_PASSWORD_FILE in setenv.sh.                   "
        echo "-------------------------------------------------------------------------------"
        exit 1
    fi

    JMX_OPTS="-Dcom.sun.management.jmxremote.port=${JMX_REMOTE_PORT} ${RMI_SERVER_HOSTNAME} -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.password.file=${JMX_PASSWORD_FILE}"

elif [ "x$JMX_REMOTE_AUTH" = "xssl" ]; then
    if [ -z "$JMX_REMOTE_PORT" ]; then
        echo ""
        echo "-------------------------------------------------------------------------------"
        echo "  Remote JMX is enabled.                                                       "
        echo "                                                                               "
        echo "  You must specify a valid port number. This is done by specifying             "
        echo "  JMX_REMOTE_PORT in setenv.sh.                                                "
        echo "-------------------------------------------------------------------------------"
        exit 1
    fi

    if [ -z "$JAVA_KEYSTORE" ] || [ ! -f "$JAVA_KEYSTORE" ]; then
        echo ""
        echo "-------------------------------------------------------------------------------"
        echo "  Remote JMX with SSL authentication is enabled.                               "
        echo "                                                                               "
        echo "  You must specify a valid path to the keystore used by Bitbucket. This is     "
        echo "  done by specifying JAVA_KEYSTORE in setenv.sh.                               "
        echo "-------------------------------------------------------------------------------"
        exit 1
    fi

    if [ -z "$JAVA_KEYSTORE_PASSWORD" ]; then
        echo ""
        echo "-------------------------------------------------------------------------------"
        echo "  Remote JMX with SSL authentication is enabled.                               "
        echo "                                                                               "
        echo "  You must specify a password to the keystore used by Bitbucket. This is       "
        echo "  done by specifying JAVA_KEYSTORE_PASSWORD in setenv.sh.                      "
        echo "-------------------------------------------------------------------------------"
        exit 1
    fi

    if [ -z "$JAVA_TRUSTSTORE" ] || [ ! -f "$JAVA_TRUSTSTORE" ]; then
        echo ""
        echo "-------------------------------------------------------------------------------"
        echo "  Remote JMX with SSL authentication is enabled.                               "
        echo "                                                                               "
        echo "  You must specify a valid path to the keystore used by Bitbucket. This is     "
        echo "  done by specifying JAVA_TRUSTSTORE in setenv.sh.                             "
        echo "-------------------------------------------------------------------------------"
        exit 1
    fi

    if [ -z "$JAVA_TRUSTSTORE_PASSWORD" ]; then
        echo ""
        echo "-------------------------------------------------------------------------------"
        echo "  Remote JMX with SSL authentication enabled.                                  "
        echo "                                                                               "
        echo "  You must specify a password to the truststore used by Bitbucket. This is     "
        echo "  done by specifying JAVA_TRUSTSTORE_PASSWORD in setenv.sh.                    "
        echo "-------------------------------------------------------------------------------"
        exit 1
    fi

    JMX_OPTS="-Dcom.sun.management.jmxremote.port=${JMX_REMOTE_PORT} ${RMI_SERVER_HOSTNAME} -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl.need.client.auth=true -Djavax.net.ssl.keyStore=${JAVA_KEYSTORE} -Djavax.net.ssl.keyStorePassword=${JAVA_KEYSTORE_PASSWORD} -Djavax.net.ssl.trustStore=${JAVA_TRUSTSTORE} -Djavax.net.ssl.trustStorePassword=${JAVA_TRUSTSTORE_PASSWORD}"
fi

BITBUCKET_HOME_MINUSD=-Dbitbucket.home=$BITBUCKET_HOME

if [ "x$JVM_LIBRARY_PATH" != "x" ]; then
    JVM_LIBRARY_PATH_MINUSD=-Djava.library.path=$JVM_LIBRARY_PATH
    JVM_REQUIRED_ARGS="${JVM_REQUIRED_ARGS} ${JVM_LIBRARY_PATH_MINUSD}"
fi

export JAVA_OPTS="-Xms${JVM_MINIMUM_MEMORY} -Xmx${JVM_MAXIMUM_MEMORY} ${JAVA_OPTS} ${JVM_REQUIRED_ARGS} ${JVM_SUPPORT_RECOMMENDED_ARGS} ${BITBUCKET_HOME_MINUSD}"

CATALINA_OPTS="${JMX_OPTS} ${CATALINA_OPTS}"
export CATALINA_OPTS

if [ "x$BITBUCKET_HOME_MINUSD" != "x" ]; then
    echo "Using BITBUCKET_HOME:      $BITBUCKET_HOME"
fi

# set the location of the pid file
if [ -z "$CATALINA_PID" ] ; then
    if [ -n "$CATALINA_BASE" ] ; then
        CATALINA_PID="$CATALINA_BASE"/work/catalina.pid
    elif [ -n "$CATALINA_HOME" ] ; then
        CATALINA_PID="$CATALINA_HOME"/work/catalina.pid
    fi
fi
export CATALINA_PID
