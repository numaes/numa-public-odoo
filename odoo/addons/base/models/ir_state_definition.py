# -*- coding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.
import datetime
import dateutil
import logging
import time
from collections import defaultdict, Mapping

from odoo import api, fields, models, SUPERUSER_ID, tools,  _
from odoo.exceptions import AccessError, UserError, ValidationError
from odoo.modules.registry import Registry
from odoo.osv import expression
from odoo.tools import pycompat
from odoo.tools.safe_eval import safe_eval

_logger = logging.getLogger(__name__)

MODULE_UNINSTALL_FLAG = '_force_unlink'


class IrState(models.Model):
    _name = 'ir.state.definition'
    _description = '''
    State definition for all models
    '''

    model_id = fields.Many2one('ir.model', 'Model', required=True)
    name = fields.Char('State name', required=True)
    code = fields.Char('State code', required=True,
                       help='Used to refer to this state at program level')

