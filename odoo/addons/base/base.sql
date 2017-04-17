-------------------------------------------------------------------------
-- Pure SQL
-------------------------------------------------------------------------

CREATE TABLE ir_actions (
  id integer,
  primary key(id)
);
CREATE TABLE ir_act_window (primary key(id)) INHERITS (ir_actions);
CREATE TABLE ir_act_report_xml (primary key(id)) INHERITS (ir_actions);
CREATE TABLE ir_act_url (primary key(id)) INHERITS (ir_actions);
CREATE TABLE ir_act_server (primary key(id)) INHERITS (ir_actions);
CREATE TABLE ir_act_client (primary key(id)) INHERITS (ir_actions);


CREATE TABLE ir_model (
  id integer,
  model varchar NOT NULL,
  name varchar,
  state varchar,
  info text,
  transient boolean,
  primary key(id)
);

CREATE TABLE ir_model_fields (
  id integer,
  model varchar NOT NULL,
  model_id integer references ir_model on delete cascade,
  name varchar NOT NULL,
  state varchar default 'base',
  field_description varchar,
  help varchar,
  ttype varchar,
  relation varchar,
  relation_field varchar,
  index boolean,
  copy boolean,
  related varchar,
  readonly boolean default False,
  required boolean default False,
  selectable boolean default False,
  translate boolean default False,
  serialization_field_id integer references ir_model_fields on delete cascade,
  relation_table varchar,
  column1 varchar,
  column2 varchar,
  store boolean,
  primary key(id)
);

CREATE TABLE res_lang (
    id integer,
    name VARCHAR(64) NOT NULL UNIQUE,
    code VARCHAR(16) NOT NULL UNIQUE,
    primary key(id)
);

CREATE TABLE res_users (
    id integer NOT NULL,
    active boolean default True,
    login varchar(64) NOT NULL UNIQUE,
    password varchar(64) default null,
    -- No FK references below, will be added later by ORM
    -- (when the destination rows exist)
    company_id integer, -- references res_company,
    partner_id integer, -- references res_partner,
    primary key(id)
);

CREATE TABLE res_groups (
    id integer NOT NULL,
    name varchar NOT NULL,
    primary key(id)
);

create table wkf (
    id integer,
    name varchar(64),
    osv varchar(64),
    on_create bool default false,
    primary key(id)
);

CREATE TABLE ir_module_category (
    id integer NOT NULL,
    create_uid integer, -- references res_users on delete set null,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    write_uid integer, -- references res_users on delete set null,
    parent_id integer REFERENCES ir_module_category ON DELETE SET NULL,
    name character varying(128) NOT NULL,
    primary key(id)
);

CREATE TABLE ir_module_module (
    id integer NOT NULL,
    create_uid integer, -- references res_users on delete set null,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    write_uid integer, -- references res_users on delete set null,
    website character varying(256),
    summary character varying(256),
    name character varying(128) NOT NULL,
    author character varying(128),
    icon varchar,
    state character varying(16),
    latest_version character varying(64),
    shortdesc character varying(256),
    category_id integer REFERENCES ir_module_category ON DELETE SET NULL,
    description text,
    application boolean default False,
    demo boolean default False,
    web boolean DEFAULT FALSE,
    license character varying(32),
    sequence integer DEFAULT 100,
    auto_install boolean default False,
    primary key(id)
);
ALTER TABLE ir_module_module add constraint name_uniq unique (name);

CREATE TABLE ir_module_module_dependency (
    id integer NOT NULL,
    create_uid integer, -- references res_users on delete set null,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    write_uid integer, -- references res_users on delete set null,
    name character varying(128),
    module_id integer REFERENCES ir_module_module ON DELETE cascade,
    primary key(id)
);

CREATE TABLE ir_model_data (
    id integer NOT NULL,
    create_uid integer,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    write_uid integer,
    noupdate boolean,
    name varchar NOT NULL,
    date_init timestamp without time zone,
    date_update timestamp without time zone,
    module varchar NOT NULL,
    model varchar NOT NULL,
    res_id integer,
    primary key(id)
);

-- Records foreign keys and constraints installed by a module (so they can be
-- removed when the module is uninstalled):
--   - for a foreign key: type is 'f',
--   - for a constraint: type is 'u' (this is the convention PostgreSQL uses).
CREATE TABLE ir_model_constraint (
    id integer NOT NULL,
    date_init timestamp without time zone,
    date_update timestamp without time zone,
    module integer NOT NULL references ir_module_module on delete restrict,
    model integer NOT NULL references ir_model on delete restrict,
    type character varying(1) NOT NULL,
    definition varchar,
    name varchar NOT NULL,
    primary key(id)
);

-- Records relation tables (i.e. implementing many2many) installed by a module
-- (so they can be removed when the module is uninstalled).
CREATE TABLE ir_model_relation (
    id integer NOT NULL,
    date_init timestamp without time zone,
    date_update timestamp without time zone,
    module integer NOT NULL references ir_module_module on delete restrict,
    model integer NOT NULL references ir_model on delete restrict,
    name varchar NOT NULL,
    primary key(id)
);  

CREATE TABLE res_currency (
    id integer,
    name varchar NOT NULL,
    symbol varchar NOT NULL,
    primary key(id)
);

CREATE TABLE res_company (
    id integer,
    name varchar NOT NULL,
    partner_id integer,
    currency_id integer,
    primary key(id)
);

CREATE TABLE res_partner (
    id integer,
    name varchar,
    company_id integer,
    primary key(id)
);

CREATE TABLE ir_object (
    id integer,
    model_id integer,
    create_uid integer, -- references res_users on delete set null,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    write_uid integer, -- references res_users on delete set null,
    primary key(id)
);

---------------------------------
-- Default objects
---------------------------------
insert into ir_model (id, model, state) VALUES (10, 'ir.model', 'active');
insert into ir_object (id, model_id) VALUES (10, 10);
insert into ir_model (id, model, state) VALUES (11, 'ir.object', 'active');
insert into ir_object (id, model_id) VALUES (11, 10);
insert into ir_model (id, model, state) VALUES (12, 'res.currency', 'active');
insert into ir_object (id, model_id) VALUES (12, 10);
insert into ir_model (id, model, state) VALUES (13, 'ir.model.data', 'active');
insert into ir_object (id, model_id) VALUES (13, 10);
insert into ir_model (id, model, state) VALUES (14, 'res.company', 'active');
insert into ir_object (id, model_id) VALUES (14, 10);
insert into ir_model (id, model, state) VALUES (15, 'res.partner', 'active');
insert into ir_object (id, model_id) VALUES (15, 10);
insert into ir_model (id, model, state) VALUES (16, 'res.users', 'active');
insert into ir_object (id, model_id) VALUES (16, 10);
insert into ir_model (id, model, state) VALUES (17, 'res.groups', 'active');
insert into ir_object (id, model_id) VALUES (17, 10);
insert into ir_model (id, model, state) VALUES (18, 'ir.model_field', 'active');
insert into ir_object (id, model_id) VALUES (18, 10);
-- ATENTION: keep in synch with models/dp.py!!!!
insert into ir_model (id, model, state) VALUES (19, 'ir.module_category', 'active');
insert into ir_object (id, model_id) VALUES (19, 10);
insert into ir_model (id, model, state) VALUES (20, 'ir.module_module', 'active');
insert into ir_object (id, model_id) VALUES (20, 10);
insert into ir_model (id, model, state) VALUES (21, 'ir.module_module_dependency', 'active');
insert into ir_object (id, model_id) VALUES (21, 10);
insert into ir_model (id, model, state) VALUES (22, 'ir.model_constraint', 'active');
insert into ir_object (id, model_id) VALUES (22, 10);
insert into ir_model (id, model, state) VALUES (23, 'ir.model_relation', 'active');
insert into ir_object (id, model_id) VALUES (23, 10);


---------------------------------
-- Default data
---------------------------------
insert into res_currency (id, name, symbol) VALUES (100, 'EUR', '€');
insert into ir_object (id, model_id) VALUES (100, 12);
insert into ir_model_data (id, name, module, model, noupdate, res_id) VALUES (101, 'EUR', 'base', 'res.currency', true, 100);
insert into ir_object (id, model_id) VALUES (101, 13);

insert into res_company (id, name, partner_id, currency_id) VALUES (102, 'My Company', 1, 1);
insert into ir_object (id, model_id) VALUES (102, 14);
insert into ir_model_data (id, name, module, model, noupdate, res_id) VALUES (103, 'main_company', 'base', 'res.company', true, 102);
insert into ir_object (id, model_id) VALUES (103, 13);

insert into res_partner (id, name, company_id) VALUES (104, 'My Company', 1);
insert into ir_object (id, model_id) VALUES (104, 15);
insert into ir_model_data (id, name, module, model, noupdate, res_id) VALUES (105, 'main_partner', 'base', 'res.partner', true, 104);
insert into ir_object (id, model_id) VALUES (105, 13);

insert into res_users (id, login, password, active, partner_id, company_id) VALUES (1, 'admin', 'admin', true, 1, 1);
insert into ir_object (id, model_id) VALUES (1, 16);
insert into ir_model_data (id, name, module, model, noupdate, res_id) VALUES (106, 'user_root', 'base', 'res.users', true, 1);
insert into ir_object (id, model_id) VALUES (106, 13);

insert into res_groups (id, name) VALUES (107, 'Employee');
insert into ir_object (id, model_id) VALUES (107, 17);
insert into ir_model_data (id, name, module, model, noupdate, res_id) VALUES (108, 'group_user', 'base', 'res.groups', true, 106);
insert into ir_object (id, model_id) VALUES (108, 13);

insert into ir_module_module (id, name) VALUES (109, 'base');
insert into ir_object (id, model_id) VALUES (109, 20);

