-------------------------------------------------------------------------
-- Pure SQL
-------------------------------------------------------------------------

CREATE TABLE ir_actions (
  id serial,
  primary key(id)
);
CREATE TABLE ir_act_window (id serial, primary key(id));
CREATE TABLE ir_act_report_xml (id serial, primary key(id));
CREATE TABLE ir_act_url (id serial, primary key(id));
CREATE TABLE ir_act_server (id serial, primary key(id));
CREATE TABLE ir_act_client (id serial, primary key(id));

CREATE TABLE ir_object (
    id serial NOT NULL,
    object_model_id integer,
    object_state_id integer,
    create_uid integer,
    create_date timestamp without time zone,
    write_uid integer,
    write_date timestamp without time zone,
    primary key(id)
);

CREATE TABLE ir_model (
    id serial NOT NULL,
    name varchar NOT NULL,
    model varchar ,
    state varchar,
    primary key(id)
);

CREATE TABLE res_users (
    id serial NOT NULL,
    active boolean default True,
    login varchar(64) NOT NULL UNIQUE,
    password varchar default null,
    -- No FK references below, will be added later by ORM
    -- (when the destination rows exist)
    company_id integer, -- references res_company,
    partner_id integer, -- references res_partner,
    create_date timestamp without time zone,
    primary key(id)
);

CREATE TABLE res_groups (
    id serial NOT NULL,
    name varchar NOT NULL,
    primary key(id)
);

CREATE TABLE ir_module_category (
    id serial NOT NULL,
    create_uid integer, -- references res_users on delete set null,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    write_uid integer, -- references res_users on delete set null,
    parent_id integer REFERENCES ir_module_category ON DELETE SET NULL,
    name character varying(128) NOT NULL,
    primary key(id)
);

CREATE TABLE ir_module_module (
    id serial NOT NULL,
    create_uid integer, -- references res_users on delete set null,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    write_uid integer, -- references res_users on delete set null,
    website character varying(256),
    summary character varying(256),
    name character varying(128) NOT NULL,
    author character varying,
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
    to_buy boolean default False,
    primary key(id)
);
ALTER TABLE ir_module_module add constraint name_uniq unique (name);

CREATE TABLE ir_module_module_dependency (
    id serial NOT NULL,
    create_uid integer, -- references res_users on delete set null,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    write_uid integer, -- references res_users on delete set null,
    name character varying(128),
    module_id integer REFERENCES ir_module_module ON DELETE cascade,
    primary key(id)
);

CREATE TABLE ir_model_fields (
    id serial NOT NULL,
    name varchar,
    model varchar,
    state varchar,
    model_id integer,
    primary key(id)
);

CREATE TABLE ir_default (
    id serial NOT NULL,
    field_id integer,
    user_id integer,
    company_id integer,
    condition varchar,
    json_value varchar,
    primary key(id)
);

CREATE TABLE ir_model_data (
    id serial NOT NULL,
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

CREATE TABLE res_currency (
    id serial,
    name varchar NOT NULL,
    symbol varchar NOT NULL,
    primary key(id)
);

CREATE TABLE res_company (
    id serial,
    name varchar NOT NULL,
    partner_id integer,
    currency_id integer,
    sequence integer,
    create_date timestamp without time zone,
    primary key(id)
);

CREATE TABLE res_partner (
    id serial,
    name varchar,
    company_id integer,
    create_date timestamp without time zone,
    primary key(id)
);

CREATE TABLE res_lang (
    id serial,
    name varchar,
    code varchar,
    active boolean,
    primary key(id)
);

CREATE TABLE ir_config_parameter (
    id serial,
    key varchar,
    value varchar,
    primary key(id)
);

CREATE TABLE ir_translation (
    id serial,
    name varchar,
    lang varchar,
    type varchar,
    res_id integer,
    value varchar,
    primary key(id)
);

CREATE TABLE ir_model_constraint (
    id serial,
    name varchar,
    definition varchar,
    model integer,
    module integer,
    type varchar,
    date_update timestamp without time zone,
    date_init timestamp without time zone,
    primary key(id)
);

CREATE TABLE ir_model_relation (
    id serial,
    name varchar,
    model integer,
    module integer,
    date_update timestamp without time zone,
    date_init timestamp without time zone,
    primary key(id)
);

CREATE TABLE ir_model_access (
    id serial,
    name varchar,
    active boolean,
    model_id integer,
    group_id integer,
    perm_read boolean,
    perm_write boolean,
    perm_create boolean,
    perm_unlink boolean,
    primary key(id)
);

CREATE TABLE ir_attachment (
    id serial,
    name varchar,
    primary key(id)
);


---------------------------------
-- Default data
---------------------------------
insert into ir_model (id, model, name) VALUES (2, 'ir.model', 'ir.model');
insert into ir_model (id, model, name) VALUES (3, 'ir.state.definition', 'ir.state.definition');
insert into ir_model (id, model, name) VALUES (4, 'res.currency', 'res.currency');
insert into ir_model (id, model, name) VALUES (5, 'res.company', 'res.company');
insert into ir_model (id, model, name) VALUES (6, 'ir.model.data', 'ir.model.data');
insert into ir_model (id, model, name) VALUES (7, 'res.groups', 'res.groups');
insert into ir_model (id, model, name) VALUES (8, 'res.users', 'res.users');
insert into ir_model (id, model, name) VALUES (9, 'ir.module.module.dependency', 'ir.module.module.dependency');
insert into ir_model (id, model, name) VALUES (10, 'ir.module.module', 'ir.module.module');
insert into ir_model (id, model, name) VALUES (11, 'res.partner', 'res.partner');
insert into ir_model (id, model, name) VALUES (12, 'ir.module.category', 'ir.module.category');
insert into ir_model (id, model, name) VALUES (13, 'ir.default', 'ir.default');
insert into ir_model (id, model, name) VALUES (14, 'ir.object', 'ir.object');
insert into ir_model (id, model, name) VALUES (15, 'res.lang', 'res.lang');
insert into ir_model (id, model, name) VALUES (16, 'ir.config_parameter', 'ir.config_parameter');
insert into ir_model (id, model, name) VALUES (17, 'ir.model.fields', 'ir.model.fields');
insert into ir_model (id, model, name) VALUES (18, 'ir.translation', 'ir.translation');
insert into ir_model (id, model, name) VALUES (19, 'ir.model.constraint', 'ir.model.constraint');
insert into ir_model (id, model, name) VALUES (20, 'ir.model.relation', 'ir.model.relation');
insert into ir_model (id, model, name) VALUES (21, 'ir.model.access', 'ir.model.access');
insert into ir_model (id, model, name) VALUES (22, 'ir.attachment', 'ir.attachment');

insert into ir_object(id, object_model_id) VALUES (2, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (3, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (4, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (5, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (6, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (7, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (8, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (9, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (10, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (11, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (12, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (13, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (14, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (15, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (16, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (17, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (18, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (19, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (20, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (21, (SELECT id FROM ir_module_module WHERE name='ir.model'));
insert into ir_object(id, object_model_id) VALUES (22, (SELECT id FROM ir_module_module WHERE name='ir.model'));

insert into ir_object(id, object_model_id) VALUES (100, (SELECT id FROM ir_module_module WHERE name='res.currency'));
insert into res_currency (id, name, symbol) VALUES (100, 'EUR', '€');

insert into ir_object(id, object_model_id) VALUES (101, (SELECT id FROM ir_module_module WHERE name='ir.model.data'));
insert into ir_model_data (id, name, module, model, noupdate, res_id)
       VALUES (101, 'EUR', 'base', 'res.currency', true, 100);

insert into ir_object(id, object_model_id) VALUES (102, (SELECT id FROM ir_module_module WHERE name='res.company'));
insert into res_company (id, name, partner_id, currency_id, create_date)
       VALUES (102, 'My Company', 104, 100, now() at time zone 'UTC');

insert into ir_object(id, object_model_id) VALUES (103, (SELECT id FROM ir_module_module WHERE name='ir.model.data'));
insert into ir_model_data (id, name, module, model, noupdate, res_id)
       VALUES (103, 'main_company', 'base', 'res.company', true, 102);

insert into ir_object(id, object_model_id) VALUES (104, (SELECT id FROM ir_module_module WHERE name='res.partner'));
insert into res_partner (id, name, company_id, create_date)
       VALUES (104, 'My Company', 102, now() at time zone 'UTC');

insert into ir_object(id, object_model_id) VALUES (105, (SELECT id FROM ir_module_module WHERE name='ir.model.data'));
insert into ir_model_data (id, name, module, model, noupdate, res_id)
       VALUES (105, 'main_partner', 'base', 'res.partner', true, 104);

insert into ir_object(id, object_model_id) VALUES (1, (SELECT id FROM ir_module_module WHERE name='res.users'));
insert into res_users (id, login, password, active, partner_id, company_id, create_date)
       VALUES (1, '__system__', NULL, false, 104, 102, now() at time zone 'UTC');

insert into ir_object(id, object_model_id) VALUES (107, (SELECT id FROM ir_module_module WHERE name='ir.model.data'));
insert into ir_model_data (id, name, module, model, noupdate, res_id)
       VALUES (107, 'user_root', 'base', 'res.users', true, 1);

insert into ir_object(id, object_model_id) VALUES (108, (SELECT id FROM ir_module_module WHERE name='res.groups'));
insert into res_groups (id, name) VALUES (108, 'Employee');

insert into ir_object(id, object_model_id) VALUES (109, (SELECT id FROM ir_module_module WHERE name='ir.model.data'));
insert into ir_model_data (id, name, module, model, noupdate, res_id)
       VALUES (109, 'group_user', 'base', 'res.groups', true, 108);

select setval('ir_object_id_seq', 10000);
