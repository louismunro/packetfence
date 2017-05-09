# PacketFence and CheckPoint firewall Single Sign On integration with LDAP groups

This document describes how to integrate PacketFence with the CheckPoint Firewall solution for LDAP user management.
The solution uses OpenLDAP with back_sql as a bridge between the firewall and the PacketFence MySQL database and allows PacketFence roles to be mapped to virtual ldap groups.

Although this document is written assuming a CentOS 7 Linux PacketFence installation it should be relatively straigtforward to implement the same solution on Debian.

## Background

PacketFence stores users, roles and devices in a MySQL database. 
The CheckPoint firewall only allows integration of groups in an LDAP directory and has no provision for an SQL backend.
To allow the firewall to query the PacketFence database we must implement support for the LDAP protocol and map LDAP objects and attributes to SQL tables. 
The OpenLDAP server has a built-in backend module (back_sql) that allows creating tables that will be used to convert from SQL rows to LDAP objects.

## Creating the SQL tables

The provided `pf_backsql.sql` script is meant to create the required tables and views.
You must provide some basic information on your organisation in order to insert the correct data into those tables.
The minimum required information is the base of the virtual LDAP tree under which your SQL data will be found.
It might make sense to reuse an existing base DN if you have one for your organization and append another level.
For example, if you already use "dc=myOrganization,dc=org" in an existing LDAP directory, you might want to use it here and use something like "dc=PF_myOrganization,dc=org".


Please edit the script, between the lines marked `EDIT HERE` and `DO NOT EDIT BELOW`.
You must provide the following values:

    @tld : The top level domain for your organization, e.g. "edu"
    @organization : A short name for your organization, e.g. "ZammitUniversity"

Thus, if your organization is "ZammitUniversity" and you want the root of your virtual LDAP directory tree to be "dc=ZammitUniversity,dc=edu", you would edit the top two lines of the script as the following:  


    SET @tld = "edu";
    SET @organization = "ZammitUniversity";

This will set the @base_fqdn variable which is used in the rest of the script.

Run the script: 

    mysql -uroot -p pf < /usr/local/pf/addons/back_sql/pf_backsql.sql 


## Installing the required packages

Install the openldap-servers, openldap-servers-sql, unixODBC and mysql-connector-odbc packages: 

   $ sudo install openldap-servers openldap-servers-sql unixODBC mysql-connector-odbc 

## Configure ODBC

Edit the /etc/odbcinst.ini file and make sure it contains the following lines: 
    
    # Driver from the mysql-connector-odbc package
    # Setup from the unixODBC package
    [MySQL]
    Description = ODBC for MySQL
    Driver      = /usr/lib/libmyodbc5.so
    Setup       = /usr/lib/libodbcmyS.so
    Driver64    = /usr/lib64/libmyodbc5.so
    Setup64     = /usr/lib64/libodbcmyS.so
    FileUsage   = 1

Then, edit the /etc/odbc.ini file and add the required configuration to access your existing PacketFence database:

    [MySQL]
    Driver = MySQL
    SERVER       = localhost # change if your database is hosted elsewhere
    PORT         = # only required if not using the default 3306
    USER         = pf_database_user
    Password     = yourpfuserpassword
    Database     = pf
    OPTION       = 3
    SOCKET       =


## Configuring OpenLDAP

You will need to edit the provided slapd.conf file and install the packetfence LDAP schema definition.

    cp /usr/local/pf/addons/back_sql/slapd.conf.example /etc/openldap/
    cp /usr/local/pf/addons/back_sql/packetfence.schema /etc/openldap/schema

Then, generate a password hash for the root user: 

   lappasswd -h {SHA}

Edit the slapd.conf: 

    vim /etc/openldap/slapd.conf

Set the following variables in the file:


defaultsearchbase       dc=example,dc=org  # your @base_fqdn as configured above in the pf_backsql.sql script

suffix		"dc=example,dc=org"   # set to the same as defaultsearchbase
rootdn		"cn=root,dc=example,dc=org" # the DN of the root user in the LDAP directory
rootpw		{SHA}xxxxxxxxxxxxxxxxx      # the password hash you generated above
dbname		MySQL               # as configured in odbc.ini
dbuser		pf                  # the user to connect to your PF database
dbpasswd	PFtestD             # the password used to connect to your PF database


Save the file and exit it.
You can then test that the OpenLDAP server can start by starting it manually in debug mode:

    # pkill slapd ; slapd -d 5 -f /etc/openldap/slapd.conf

The output will be "copious" and detailed.
If there are any errors reported, investigate them and fix them before proceeding further.


## Testing 

It should now be possible to query OpenLDAP using ldapsearch for either MAC addresses or group membership.

For example:
    # ldapsearch -LLL -h localhost -a always -D "cn=root,dc=example,dc=org" -w PFtestDB -b 'dc=example,dc=org' '(&(|(|(|(objectclass=person)(objectclass=organizationalPerson))(objectclass=inetOrgPerson))(objectclass=fw1Person))(uid=00:24:e8:9d:65:31$))'
    dn: macAddress=00:24:E8:9D:65:31,dc=example,dc=org
    objectClass: person
    cn: 00:24:e8:9d:65:31
    uid: 00:24:e8:9d:65:31$
    host: bacchus
    macAddress: 00:24:e8:9d:65:31
    ipHostNumber: 10.81.48.11

    # ldapsearch -LLL -h localhost -a never  -s sub -D "cn=root,dc=example,dc=org" -w PFtestDB -b 'cn=guest,dc=example,dc=org' '(&(|(objectclass=groupOfNames)(objectclass=groupOfUniqueNames))(|(member=macAddress=00:24:E8:9D:65:31,dc=example,dc=org)(uniqueMember=macAddress=00:24:E8:9D:65:31,dc=example,dc=org)))' cn objectclass member
    dn: cn=GUEST,dc=example,dc=org
    objectClass: groupOfNames
    cn: guest
    member: macAddress=00:24:E8:9D:65:31,dc=example,dc=org
    member: macAddress=28:F1:0E:48:EC:C0,dc=example,dc=org
    member: macAddress=C8:BC:C8:89:CA:51,dc=example,dc=org
    member: macAddress=D4:81:D7:90:68:7E,dc=example,dc=org


Note that since PacketFence considers MAC addresses to be the primary key for a node (as it manages devices), endpoints are considered as having the objectClass "person" for LDAP purposes.


##  Configuring the Firewall
TODO

##  Notes 
This configuration has been tested with the following packages versions:


Due to the use of SQL views, and the way that objects are mapped from SQL to LDAP, performance may be less than ideal. This solution may not scale well above a few hundreds to thousands of devices in use. 
A better solution would involve sending the group information to the firewall directly through RADIUS accounting but that was not supported at the time this was tested.
