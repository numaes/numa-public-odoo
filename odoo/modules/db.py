# -*- coding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

import odoo.modules
import logging
import random

_logger = logging.getLogger(__name__)

def is_initialized(cr):
    """ Check if a database has been initialized for the ORM.

    The database can be initialized with the 'initialize' function below.

    """
    return odoo.tools.table_exists(cr, 'ir_module_module')

def initialize(cr):
    """ Initialize a database with for the ORM.

    This executes base/data/base_data.sql, creates the ir_module_categories
    (taken from each module descriptor file), and creates the ir_module_module
    and ir_model_data entries.

    """
    try:
        f = odoo.modules.get_module_resource('base', 'data', 'base_data.sql')
        if not f:
            m = "File not found: 'base.sql' (provided by module 'base')."
            _logger.critical(m)
            raise IOError(m)

        with odoo.tools.misc.file_open(f) as base_sql_file:
            cr.execute(base_sql_file.read())

        irModelRecords = {}
        cr.execute('SELECT id,name FROM ir_model')
        for modelId, modelName in cr.fetchall():
            irModelRecords[modelName] = modelId

        idCounter = 400
        for i in odoo.modules.get_modules():
            mod_path = odoo.modules.get_module_path(i)
            if not mod_path:
                continue

            # This will raise an exception if no/unreadable descriptor file.
            info = odoo.modules.load_information_from_description_file(i)

            if not info:
                continue
            categories = info['category'].split('/')
            category_id, idCounter = create_categories(cr, categories, idCounter)

            if info['installable']:
                state = 'uninstalled'
            else:
                state = 'uninstallable'

            cr.execute('INSERT INTO ir_module_module \
                    (id, author, website, name, shortdesc, description, \
                        category_id, auto_install, state, web, license, application, icon, sequence, summary) \
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING id', (
                idCounter,
                info['author'],
                info['website'], i, info['name'],
                info['description'], category_id,
                info['auto_install'], state,
                info['web'],
                info['license'],
                info['application'], info['icon'],
                info['sequence'], info['summary']))
            id = cr.fetchone()[0]
            cr.execute('INSERT INTO ir_object (id, object_model_id) VALUES (%s, %s)' %
                       (idCounter, irModelRecords['ir.module.module']))
            idCounter += 1
            cr.execute('INSERT INTO ir_model_data \
                (id, name,model,module, res_id, noupdate) VALUES (%s,%s,%s,%s,%s,%s)', (
                    idCounter,'module_'+i, 'ir.module.module', 'base', id, True))
            cr.execute('INSERT INTO ir_object (id, object_model_id) VALUES (%s, %s)' %
                       (idCounter, irModelRecords['ir.model.data']))
            idCounter += 1
            dependencies = info['depends']
            for d in dependencies:
                cr.execute('INSERT INTO ir_module_module_dependency \
                        (id,module_id,name) VALUES (%s, %s, %s)', (idCounter, id, d))
                cr.execute('INSERT INTO ir_object (id, object_model_id) VALUES (%s, %s)' %
                           (idCounter, irModelRecords['ir.module.module.dependency']))
                idCounter += 1

        # Install recursively all auto-installing modules
        while True:
            cr.execute("""SELECT m.name FROM ir_module_module m WHERE m.auto_install AND state != 'to install'
                          AND NOT EXISTS (
                              SELECT 1 FROM ir_module_module_dependency d JOIN ir_module_module mdep ON (d.name = mdep.name)
                                       WHERE d.module_id = m.id AND mdep.state != 'to install'
                          )""")
            to_auto_install = [x[0] for x in cr.fetchall()]
            if not to_auto_install: break
            cr.execute("""UPDATE ir_module_module SET state='to install' WHERE name in %s""", (tuple(to_auto_install),))

        _logger.info("Database initialized")

    except Exception as e:
        import sys, os
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        _logger.info(exc_type, fname, exc_tb.tb_lineno)
        _logger.error("Unexpected exception during loading: %s", str(e))
        raise

def create_categories(cr, categories, idCounter=None):
    """ Create the ir_module_category entries for some categories.

    categories is a list of strings forming a single category with its
    parent categories, like ['Grand Parent', 'Parent', 'Child'].

    Return the database id of the (last) category.

    """
    p_id = None
    category = []

    if not idCounter:
        newId = random.randint(10000, 2147483647)
    else:
        newId = idCounter

    irModelRecords = {}
    cr.execute('SELECT id,name FROM ir_model')
    for modelId, modelName in cr.fetchall():
        irModelRecords[modelName] = modelId

    while categories:
        category.append(categories[0])
        xml_id = 'module_category_' + ('_'.join(x.lower() for x in category)).replace('&', 'and').replace(' ', '_')
        # search via xml_id (because some categories are renamed)
        cr.execute("SELECT res_id FROM ir_model_data WHERE name=%s AND module=%s AND model=%s",
                   (xml_id, "base", "ir.module.category"))

        c_id = cr.fetchone()
        if not c_id:
            cr.execute('INSERT INTO ir_module_category \
                    (id, name, parent_id) \
                    VALUES (%s, %s, %s) RETURNING id', (idCounter, categories[0], p_id))
            c_id = cr.fetchone()[0]
            cr.execute('INSERT INTO ir_object (id, object_model_id) VALUES (%s, %s)' %
                       (idCounter, irModelRecords['ir.module.category']))
            idCounter += 1
            cr.execute('INSERT INTO ir_model_data (id, module, name, res_id, model) \
                       VALUES (%s, %s, %s, %s, %s)', (idCounter, 'base', xml_id, c_id, 'ir.module.category'))
            cr.execute('INSERT INTO ir_object (id, object_model_id) VALUES (%s, %s)' %
                       (idCounter, irModelRecords['ir.model.data']))
            idCounter += 1
        else:
            c_id = c_id[0]
        p_id = c_id
        categories = categories[1:]

    if idCounter:
        return p_id, idCounter
    else:
        return p_id

def has_unaccent(cr):
    """ Test if the database has an unaccent function.

    The unaccent is supposed to be provided by the PostgreSQL unaccent contrib
    module but any similar function will be picked by OpenERP.

    """
    cr.execute("SELECT proname FROM pg_proc WHERE proname='unaccent'")
    return len(cr.fetchall()) > 0
