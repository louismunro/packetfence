-- EDIT HERE 

SET @tld = "ch";
SET @organization = "unibas";

-- DO NOT EDIT BELOW THIS LINE

SET @top_rdn = concat_ws("=", "dc", @tld);  
SET @level1_rdn = concat_ws("=", "dc", @organization);
SET @base_fqdn = concat_ws(",", @level1_rdn, @top_rdn);

drop table if exists ldap_oc_mappings;
create table ldap_oc_mappings
 (
	id integer unsigned not null primary key auto_increment,
	name varchar(64) not null,
	keytbl varchar(64) not null,
	keycol varchar(64) not null,
	create_proc varchar(255),
	delete_proc varchar(255),
	expect_return tinyint not null
);

drop table if exists ldap_attr_mappings;
create table ldap_attr_mappings
 (
	id integer unsigned not null primary key auto_increment,
	oc_map_id integer unsigned not null references ldap_oc_mappings(id),
	name varchar(255) not null,
	sel_expr varchar(255) not null,
	sel_expr_u varchar(255),
	from_tbls varchar(255) not null,
	join_where varchar(255),
	add_proc varchar(255),
	delete_proc varchar(255),
	param_order tinyint not null,
	expect_return tinyint not null
);


drop table if exists ldap_entry_objclasses;
create table ldap_entry_objclasses
 (
	entry_id integer not null references ldap_entries(id),
	oc_name varchar(64)
 );


drop table if exists institutes;
CREATE TABLE institutes (
	id int NOT NULL,
	name varchar(255)
);

insert into institutes (id,name) values (1,@organization);
-- mappings 

-- objectClass mappings: these may be viewed as structuralObjectClass, the ones that are used to decide how to build an entry
--	id		a unique number identifying the objectClass
--	name		the name of the objectClass; it MUST match the name of an objectClass that is loaded in slapd's schema
--	keytbl		the name of the table that is referenced for the primary key of an entry
--	keycol		the name of the column in "keytbl" that contains the primary key of an entry; the pair "keytbl.keycol" uniquely identifies an entry of objectClass "id"
--	create_proc	a procedure to create the entry
--	delete_proc	a procedure to delete the entry; it takes "keytbl.keycol" of the row to be deleted
--	expect_return	a bitmap that marks whether create_proc (1) and delete_proc (2) return a value or not
insert into ldap_oc_mappings (id,name,keytbl,keycol,create_proc,delete_proc,expect_return)
values (1,'organization','institutes','id',NULL,NULL,0);

insert into ldap_oc_mappings (id,name,keytbl,keycol,create_proc,delete_proc,expect_return)
values (2,'person','ldap_node','id',NULL,NULL,0);

insert into ldap_oc_mappings (id,name,keytbl,keycol,create_proc,delete_proc,expect_return)
values (3,'groupOfNames','ldap_category','category_id',NULL,NULL,0);

-- attributeType mappings: describe how an attributeType for a certain objectClass maps to the SQL data.
--	id		a unique number identifying the attribute	
--	oc_map_id	the value of "ldap_oc_mappings.id" that identifies the objectClass this attributeType is defined for
--	name		the name of the attributeType; it MUST match the name of an attributeType that is loaded in slapd's schema
--	sel_expr	the expression that is used to select this attribute (the "select <sel_expr> from ..." portion)
--	from_tbls	the expression that defines the table(s) this attribute is taken from (the "select ... from <from_tbls> where ..." portion)
--	join_where	the expression that defines the condition to select this attribute (the "select ... where <join_where> ..." portion)
--	add_proc	a procedure to insert the attribute; it takes the value of the attribute that is added, and the "keytbl.keycol" of the entry it is associated to
--	delete_proc	a procedure to delete the attribute; it takes the value of the attribute that is added, and the "keytbl.keycol" of the entry it is associated to
--	param_order	a mask that marks if the "keytbl.keycol" value comes before or after the value in add_proc (1) and delete_proc (2)
--	expect_return	a mask that marks whether add_proc (1) and delete_proc(2) are expected to return a value or not
insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (1,2,'host',"ldap_node.computername",'ldap_node',NULL,NULL,NULL,3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (2,2,'ipHostNumber','ldap_iplog.ip','ldap_iplog,ldap_node', 'ldap_iplog.id=ldap_node.id' ,NULL,NULL,3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (3,2,'macAddress','ldap_node.mac','ldap_node',NULL,NULL,NULL,3,0);


insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (4,2,'uid','ldap_node.uid','ldap_node',NULL,NULL,NULL,3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (5,2,'cn','ldap_node.mac','ldap_node',NULL,NULL,NULL,3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (6,3,'member','ldap_node.dn','ldap_node,ldap_category','ldap_node.category_id=ldap_category.category_id',NULL,NULL,3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (7,3,'cn','cn','ldap_category',NULL,NULL,NULL,3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (8,1,'o','institutes.name','institutes',NULL,NULL,NULL,3,0);

insert into ldap_attr_mappings (id,oc_map_id,name,sel_expr,from_tbls,join_where,add_proc,delete_proc,param_order,expect_return)
values (9,1,'dc','lower(institutes.name)','institutes,ldap_entries AS dcObject,ldap_entry_objclasses as auxObjectClass',
	'institutes.id=dcObject.keyval AND dcObject.oc_map_id=3 AND dcObject.id=auxObjectClass.entry_id AND auxObjectClass.oc_name=''dcObject''',
	NULL,NULL,3,0);

-- entries mapping: each entry must appear in this table, with a unique DN rooted at the database naming context
--	id		a unique number > 0 identifying the entry
--	dn		the DN of the entry, in "pretty" form
--	oc_map_id	the "ldap_oc_mappings.id" of the main objectClass of this entry (view it as the structuralObjectClass)
--	parent		the "ldap_entries.id" of the parent of this objectClass; 0 if it is the "suffix" of the database
--	keyval		the value of the "keytbl.keycol" defined for this objectClass
DROP VIEW IF EXISTS `ldap_iplog`;
CREATE VIEW `ldap_iplog` AS
    SELECT 
        CONV(REPLACE(`iplog`.`mac`, ':', ''), 16, 10) AS `id`,
        mac,
        ip,
        start_time,
        end_time
    FROM
        iplog;

DROP VIEW IF EXISTS `ldap_node`;
CREATE VIEW `ldap_node` AS
    SELECT 
        CONV(REPLACE(`node`.`mac`, ':', ''), 16, 10) AS `id`, 
        mac,
        UCASE(
            CONCAT(
                CONCAT('macAddress=', `mac`), 
                CONCAT(',',@base_fqdn)
            )
        ) AS `dn`,
        CONCAT(`node`.`mac`,'$') as uid,
        computername,
        status,
        pid,
        category_id
    FROM
        node;

DROP VIEW IF EXISTS `ldap_category`;
CREATE VIEW `ldap_category` AS
     SELECT
        `node_category`.`category_id` AS `category_id`,
        `node_category`.`name` AS `cn`,
        `node_category`.`name` AS `name`
     FROM 
        `node_category`;
        

DROP VIEW IF EXISTS `ldap_entries`;
CREATE VIEW `ldap_entries` AS
    SELECT 
        281474976710656  AS `id`, -- the maximum possible value for a MAC +1 
        UCASE(@base_fqdn) AS `dn`,
        1 AS `oc_map_id`,
        0 AS `parent`,
        1 AS `keyval`
    FROM
        `ldap_node` 
    UNION SELECT 
        CONV(REPLACE(`ldap_node`.`mac`, ':', ''), 16, 10) AS `id`,
        UCASE(
            CONCAT(
                CONCAT('macAddress=', `ldap_node`.`mac`),
                CONCAT(',', @base_fqdn)
            ) 
        ) AS `dn`, 
        2 AS `oc_map_id`, 
        1 AS `parent`, 
        `ldap_node`.`id` AS `keyval`  
    FROM
        `ldap_node`
    UNION SELECT
        (281474976710656 + 2 + `category_id`) AS `id`, -- something large enough never to conflict with MAC addresses
        UCASE(
            CONCAT(
                CONCAT('cn=', `name`),
                CONCAT(',', @base_fqdn)
            ) 
        ) AS `dn`,
        3 AS `oc_map_id`,
        1 AS `parent`,
        `category_id` AS `keyval`
    FROM 
        `node_category`;



-- objectClass mapping: entries that have multiple objectClass instances are listed here with the objectClass name (view them as auxiliary objectClass)
--	entry_id	the "ldap_entries.id" of the entry this objectClass value must be added
--	oc_name		the name of the objectClass; it MUST match the name of an objectClass that is loaded in slapd's schema
insert into ldap_entry_objclasses (entry_id,oc_name)
values (0,'dcObject');
