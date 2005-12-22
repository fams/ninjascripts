<?php
/**
 * $Horde: turba/config/sources.php.dist,v 1.97.6.3 2005/02/08 20:43:47 chuck Exp $
 *
 * This file is where you specify the sources of contacts available to users at
 * your installation.  It contains a large number of EXAMPLES.  Please remove
 * or comment out those examples that YOU DON'T NEED.
 * There are a number of properties that you can set for each server,
 * including:
 *
 * title:    This is the common (user-visible) name that you want displayed in
 *           the contact source drop-down box.
 *
 * type:     The types 'ldap', 'sql', 'imsp' and 'prefs' are currently
 *           supported.  Preferences-based addressbooks are not intended for
 *           production installs unless you really know what you're doing -
 *           they are not searchable, and they won't scale well if a user has a
 *           large number of entries.
 *
 * params:   These are the connection parameters specific to the contact
 *           source.  See below for examples of how to set these.
 *
 * Special params settings:
 *
 *   charset:  The character set that the backend stores data in. Many LDAP
 *             servers use utf-8. Database servers typically use iso-8859-1.
 *
 *   tls:      Only applies to LDAP servers. If true, then try to use a TLS
 *             connection to the server.
 *
 * map:      This is a list of mappings from the standard Turba attribute names
 *           (on the left) to the attribute names by which they are known in
 *           this contact source (on the right).  Turba also supports composite
 *           fields.  A composite field is defined by mapping the field name to
 *           an array containing a list of component fields and a format string
 *           (similar to a printf() format string).  Here is an example:
 *           ...
 *           'name' => array('fields' => array('firstname', 'lastname'),
 *                           'format' => '%s %s'),
 *           'firstname' => 'object_firstname',
 *           'lastname' => 'object_lastname',
 *           ...
 *
 * tabs:     All fields can be grouped into tabs with this optional entry. This
 *           list is multidimensional hash, the keys are the tab titles.  Here
 *           is an example:
 *           'tabs' => array(
 *               'Names' => array('firstname', 'lastname', 'alias'),
 *               'Addresses' => array('homeAddress', 'workAddress')
 *           );
 *
 * search:   A list of Turba attribute names that can be searched for this
 *           source.
 *
 * strict:   A list of native field/attribute names that must always be matched
 *           exactly in a search.
 *
 * public:   If set to true, this source will be available to all users.  See
 *           also 'readonly' -- public=true readonly=false means writable by
 *           all users!
 *
 * readonly: If set to true, this source can only be modified by users on the
 *           'admin' list.
 *
 * admin:    A list (array) of users that are allowed to modify this source, if
 *           it's marked 'readonly'.
 *
 * export:   If set to true, this source will appear on the Export menu,
 *           allowing users to export the contacts to a CSV (etc.) file.
 *
 * Here are some example configurations:
 */
/**
 * A local address book in an LDAP directory. This implements a public
 * (shared) address book.
 * To store freebusy information in the LDAP directory, you'll need
 * the rfc2739.schema from ftp://kalamazoolinux.org/pub/projects/awilliam/misc-ldap/.
 */
$cfgSources['localldap'] = array(
    'title' => _("Usuários %EMPRESA%"),
    'type' => 'ldap',
    'params' => array(
        'server' => 'localhost',
        'port' => 389,
        'tls' => false,
        'root' => 'ou=People,%SUFFIX%',
        'bind_dn' => 'cn=proxyuser,ou=Staff,%SUFFIX%',
        'bind_password' => '%LDAPPROXYPASS%',
        'sizelimit' => 200,
        'dn' => array('cn'),
        'objectclass' => array('top',
                               'person',
                               'organizationalPerson','inetOrgPerson'),
        'charset' => 'iso-8859-1',
        // check if all required attributes for an entry are set and add them
        // if needed.
        'checkrequired' => false,
        // string to put in missing required attributes.
        'checkrequired_string' => ' ',
        'version' => 3
    ),
    'map' => array(
        '__key' => 'dn',
        '__uid' => 'uid',
        'name' => 'cn',
        'email' => 'mail',
        'homePhone' => 'homephone',
        'workPhone' => 'telephonenumber',
        'cellPhone' => 'mobiletelephonenumber',
        'homeAddress' => 'homepostaladdress'
        // 'freebusyUrl' => 'calFBURL'
    ),
    'search' => array(
        'name',
        'email',
        'homePhone',
        'workPhone',
        'cellPhone',
        'homeAddress'
    ),
    'strict' => array(
        'dn',
    ),
    'public' => true,
    'readonly' => true,
    'admin' => array(),
    'export' => true
);

/**
 * A personal adressbook. This assumes that the login is
 * <username>@domain.com and that the users are stored on the same
 * LDAP server. Thus it is possible to bind with the username and
 * password from the user. For more info; please refer to the
 * docs/LDAP file in the Turba distribution.
 *
 * To store freebusy information in the LDAP directory, you'll need
 * the rfc2739.schema from ftp://kalamazoolinux.org/pub/projects/awilliam/misc-ldap/.
 */

// First we need to get the uid.
$uid = Auth::getBareAuth();
$basedn = '%SUFFIX%';
$cfgSources['personal_ldap'] = array(
    'title' => _("Catálogo de endereços Pessoal"),
    'type' => 'ldap',
    'params' => array(
        'server' => 'localhost',
        'tls' => false,
        'root' => 'ou=' . $uid . ',ou=personal_addressbook,' . $basedn,
        'bind_dn' => 'uid=' . $uid . ',ou=People,' . $basedn,
        'bind_password' => Auth::getCredential('password'),
        'dn' => array('cn', 'uid'),
        'objectclass' => array('top',
                               'person',
                               'inetOrgPerson',
                               // 'calEntry',
                               'organizationalPerson'),
        'charset' => 'utf-8',
        'version' => 3
    ),
    'map' => array(
        '__key' => 'dn',
        '__uid' => 'uid',
        'name' => 'cn',
        'email' => 'mail',
        'lastname' => 'sn',
        'title' => 'title',
        'company' => 'organizationname',
        'businessCategory' => 'businesscategory',
        'workAddress' => 'postaladdress',
        'workPostalCode' => 'postalcode',
        'workPhone' => 'telephonenumber',
        'fax' => 'facsimiletelephonenumber',
        'homeAddress' => 'homepostaladdress',
        'homePhone' => 'homephone',
        'cellPhone' => 'mobile',
        'notes' => 'description',
        // Evolution interopt attributes:  (those that do not require the evolution.schema)
        'office' => 'roomNumber',
        'department' => 'ou',
        'nickname' => 'displayName',
        'website' => 'labeledURI',

        // These are not stored on the LDAP server.
        'pgpPublicKey' => 'object_pgppublickey',
        'smimePublicKey' => 'object_smimepublickey',

        // From rfc2739.schema:
        // 'freebusyUrl' => 'calFBURL',

    ),
    'search' => array(
        'name',
        'email',
        'businessCategory',
        'title',
        'homePhone',
        'workPhone',
        'cellPhone',
        'homeAddress'
    ),
    'strict' => array(
        'dn',

    ),
    'public' => true,
    'readonly' => false,
    'admin' => array($uid),
    'export' => true
);

/**
 * A preferences-based adressbook. This will always be private. You
 * can add any attributes you like to the map and it will just work;
 * you can also create multiple prefs-based addressbooks by changing
 * the 'name' parameter. This is best for addressbooks that are
 * expected to remain small; it's not the most efficient, but it can't
 * be beat for getting up and running quickly, especially if you
 * already have Horde preferences working. Note that it is not
 * searchable, though - searches will simply return the whole
 * addressbook.
 */
//$cfgSources['prefs'] = array(
//    'title' => _("Catálogo de endereços Pessoal"),
//    'type' => 'prefs',
//    'params' => array(
//        'name' => 'prefs',
//        'charset' => NLS::getCharset()
//    ),
//    'map' => array(
//        '__key' => 'id',
//        '__type' => '_type',
//        '__members' => '_members',
//        '__uid' => 'uid',
//        'name' => 'name',
//        'email' => 'mail',
//        'alias' => 'alias'
//    ),
//    'search' => array(
//        'name',
//        'email',
//        'alias'
//    ),
//    'strict' => array(
//        'id',
//        '_type',
//    ),
//    'public' => false,
//    'readonly' => false,
//    'export' => false
//);

/**
 * A shared adressbook. This assumes that the login is
 * <username>@domain.com and that the users are stored on the same
 * LDAP server. Thus it is possible to bind with the username and
 * password from the user. For more info; please refer to the
 * docs/LDAP file in the Turba distribution.
 *
 * To store freebusy information in the LDAP directory, you'll need
 * the rfc2739.schema from ftp://kalamazoolinux.org/pub/projects/awilliam/misc-ldap/.
 */

// First we need to get the uid.
$uid = Auth::getBareAuth();
$basedn = '%SUFFIX%';
$cfgSources['shared_ldap'] = array(
    'title' => _("Catálogo de endereços Compartilhado"),
    'type' => 'ldap',
    'params' => array(
        'server' => 'localhost',
        'tls' => false,
        'root' => 'ou=100,ou=personal_addressbook,' . $basedn,
        'bind_dn' => 'uid=' . $uid . ',ou=People,' . $basedn,
        'bind_password' => Auth::getCredential('password'),
        'dn' => array('cn'),
        'objectclass' => array('top',
                               'person',
                               'inetOrgPerson',
                               // 'calEntry',
                               'organizationalPerson'),
        'charset' => 'utf-8',
        'version' => 3
    ),
    'map' => array(
        '__key' => 'dn',
        'name' => 'cn',
        'email' => 'mail',
        'lastname' => 'sn',
        'title' => 'title',
        'company' => 'organizationname',
        'businessCategory' => 'businesscategory',
        'workAddress' => 'postaladdress',
        'workPostalCode' => 'postalcode',
        'workPhone' => 'telephonenumber',
        'fax' => 'facsimiletelephonenumber',
        'homeAddress' => 'homepostaladdress',
        'homePhone' => 'homephone',
        'cellPhone' => 'mobile',
        'notes' => 'description',
        // Evolution interopt attributes:  (those that do not require the evolution.schema)
        'office' => 'roomNumber',
        'department' => 'ou',
        'nickname' => 'displayName',
        'website' => 'labeledURI',

        // These are not stored on the LDAP server.
        'pgpPublicKey' => 'object_pgppublickey',
        'smimePublicKey' => 'object_smimepublickey',

        // From rfc2739.schema:
        // 'freebusyUrl' => 'calFBURL',

    ),
    'search' => array(
        'name',
        'email',
        'businessCategory',
        'title',
        'homePhone',
        'workPhone',
        'cellPhone',
        'homeAddress'
    ),
    'strict' => array(
        'dn',

    ),
    'public' => true,
    'readonly' => true,
    'admin' => array('%ADMIN%'),
    'export' => true
);

