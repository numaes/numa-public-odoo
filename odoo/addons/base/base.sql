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
    id serial NOT NULL,
    name varchar NOT NULL,
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

CREATE TABLE ir_instance_state (
    id integer,
    code varchar,
    name varchar,
    base_model_id integer,
    primary key(id)
);

CREATE TABLE ir_instance (
    id integer,
    base_model_id integer,
    create_date timestamp without time zone,
    create_uid integer,
    write_date timestamp without time zone,
    write_uid integer,
    current_state_id integer,
    primary key(id)
);

CREATE TABLE ir_model (
    id integer,
    name varchar,
    primary key(id)
);

---------------------------------
-- Default data
---------------------------------

insert into res_users (id, login, password, active, partner_id, company_id) VALUES (1, 'admin', 'admin', true, 1, 1);
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (1, 3, now(), 1, now(), 1);

insert into ir_model (id, name) VALUES (2, 'ir.model');
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (2, 2, now(), 1, now(), 1);

insert into ir_model (id, name) VALUES (3, 'res.users');
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (3, 2, now(), 1, now(), 1);

insert into ir_model (id, name) VALUES (4, 'res.currency');
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (4, 2, now(), 1, now(), 1);

insert into ir_model (id, name) VALUES (5, 'res.company');
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (5, 2, now(), 1, now(), 1);

insert into ir_model (id, name) VALUES (6, 'res.partner');
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (6, 2, now(), 1, now(), 1);

insert into ir_model (id, name) VALUES (7, 'res.groups');
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (7, 2, now(), 1, now(), 1);

insert into ir_model (id, name) VALUES (8, 'ir.model.data');
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (8, 2, now(), 1, now(), 1);


insert into res_currency (id, name, symbol) VALUES (9, 'EUR', '€');
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (9, 4, now(), 1, now(), 1);
insert into ir_model_data (id, name, module, model, noupdate, res_id) VALUES (10, 'EUR', 'base', 'res.currency', true, 9);
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (10, 8, now(), 1, now(), 1);

insert into res_company (id, name, partner_id, currency_id) VALUES (11, 'My Company', 1, 1);
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (11, 5, now(), 1, now(), 1);
insert into ir_model_data (id, name, module, model, noupdate, res_id) VALUES (12, 'main_company', 'base', 'res.company', true, 11);
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (12, 8, now(), 1, now(), 1);

insert into res_partner (id, name, company_id) VALUES (13, 'My Company', 1);
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (13, 6, now(), 1, now(), 1);
insert into ir_model_data (14, name, module, model, noupdate, res_id) VALUES (14, 'main_partner', 'base', 'res.partner', true, 13);
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (14, 8, now(), 1, now(), 1);

insert into ir_model_data (id, name, module, model, noupdate, res_id) VALUES (15, 'user_root', 'base', 'res.users', true, 1);
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (15, 8, now(), 1, now(), 1);

insert into res_groups (id, name) VALUES (16, 'Employee');
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (16, 7, now(), 1, now(), 1);
insert into ir_model_data (id, name, module, model, noupdate, res_id) VALUES (17, 'group_user', 'base', 'res.groups', true, 16);
insert into ir_instance (id, base_model_id, create_date, create_uid, write_date, write_uid) VALUES (17, 8, now(), 1, now(), 1);
