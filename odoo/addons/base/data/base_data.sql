-------------------------------------------------------------------------
-- Pure SQL
-------------------------------------------------------------------------

CREATE TABLE ir_actions (
  id serial,
  primary key(id)
);
CREATE TABLE ir_act_window (primary key(id)) INHERITS (ir_actions);
CREATE TABLE ir_act_report_xml (primary key(id)) INHERITS (ir_actions);
CREATE TABLE ir_act_url (primary key(id)) INHERITS (ir_actions);
CREATE TABLE ir_act_server (primary key(id)) INHERITS (ir_actions);
CREATE TABLE ir_act_client (primary key(id)) INHERITS (ir_actions);

CREATE TABLE ir_object (
    id serial NOT NULL,
    object_model_id integer,
    object_state_id integer,
    create_uid integer,
    create_date timestamp without time zone,
    write_uid integer,
    write_date timestamp without time zone,
);

CREATE TABLE ir_model (
    id serial NOT NULL,
    name varchar NOT NULL,
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


---------------------------------
-- Default data
---------------------------------
insert into ir_model (id, name) VALUES (1, 'ir.object');
insert into ir_model (id, name) VALUES (2, 'ir.model');
insert into ir_model (id, name) VALUES (3, 'ir.state.definition');
insert into ir_model (id, name) VALUES (4, 'res.currency');
insert into ir_model (id, name) VALUES (5, 'res.company');
insert into ir_model (id, name) VALUES (6, 'ir.model_data');
insert into ir_model (id, name) VALUES (7, 'res.groups');
insert into ir_model (id, name) VALUES (8, 'res.users');
insert into ir_model (id, name) VALUES (9, 'ir.module.module_dependency');
insert into ir_model (id, name) VALUES (10, 'ir.module.module');
insert into ir_model (id, name) VALUES (11, 'res.partner');

insert into ir_object(id, object_model_id) VALUES (1, 2);
insert into ir_object(id, object_model_id) VALUES (2, 2);
insert into ir_object(id, object_model_id) VALUES (3, 2);
insert into ir_object(id, object_model_id) VALUES (4, 2);
insert into ir_object(id, object_model_id) VALUES (5, 2);
insert into ir_object(id, object_model_id) VALUES (6, 2);
insert into ir_object(id, object_model_id) VALUES (7, 2);
insert into ir_object(id, object_model_id) VALUES (8, 2);
insert into ir_object(id, object_model_id) VALUES (9, 2);
insert into ir_object(id, object_model_id) VALUES (10, 2);
insert into ir_object(id, object_model_id) VALUES (11, 2);

insert into res_currency (id, name, symbol) VALUES (100, 'EUR', '€');
insert into ir_object(id, object_model_id) VALUES (100, 4);
insert into ir_model_data (id, name, module, model, noupdate, res_id) VALUES (101, 'EUR', 'base', 'res.currency', true, 100);
insert into ir_object(id, object_model_id) VALUES (101, 6);

insert into res_company (id, name, partner_id, currency_id, create_date) VALUES (102, 'My Company', 1, 1, now() at time zone 'UTC');
insert into ir_object(id, object_model_id) VALUES (102, 5);
insert into ir_model_data (id, name, module, model, noupdate, res_id) VALUES (103, 'main_company', 'base', 'res.company', true, 102);
insert into ir_object(id, object_model_id) VALUES (103, 6);

insert into res_partner (id, name, company_id, create_date) VALUES (104, 'My Company', 1, now() at time zone 'UTC');
insert into ir_object(id, object_model_id) VALUES (104, 11);
insert into ir_model_data (id, name, module, model, noupdate, res_id) VALUES (105, 'main_partner', 'base', 'res.partner', true, 104);
insert into ir_object(id, object_model_id) VALUES (105, 6);

insert into res_users (id, login, password, active, partner_id, company_id, create_date) VALUES (106, '__system__', NULL, false, 1, 1, now() at time zone 'UTC');
insert into ir_object(id, object_model_id) VALUES (106, 8);
insert into ir_model_data (id, name, module, model, noupdate, res_id) VALUES (107, 'user_root', 'base', 'res.users', true, 106);
insert into ir_object(id, object_model_id) VALUES (107, 6);

insert into res_groups (id, name) VALUES (108, 'Employee');
insert into ir_object(id, object_model_id) VALUES (108, 7);
insert into ir_model_data (id, name, module, model, noupdate, res_id) VALUES (109, 'group_user', 'base', 'res.groups', true, 108);
insert into ir_object(id, object_model_id) VALUES (109, 6);

select setval('ir_object_id_seq', 1000);
