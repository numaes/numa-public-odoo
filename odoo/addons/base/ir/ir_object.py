# -*- coding: utf-8 -*-
# Copyright NUMA Extreme Systems. License AGPL-3

import datetime
import dateutil
import logging
import time
from collections import defaultdict

from odoo import api, fields, models, SUPERUSER_ID, tools,  _
from odoo.exceptions import AccessError, UserError, ValidationError
from odoo.modules.registry import Registry
from odoo.tools.safe_eval import safe_eval

_logger = logging.getLogger(__name__)


class IrObject(models.Model):
    _name = 'ir.object'

    model_id = fields.Many2one('ir.model', 'Model', required=True, readonly=True)
    create_uid = fields.Many2one('res.users', 'Created by')
    create_date = fields.Datetime('Create date')
    write_uid = fields.Many2one('res.users', 'Last Written by')
    write_date = fields.Datetime('Last written date')

    @api.model
    def create(self, vals):
        raise UserError(_('ir.object should not be manipulated via ORM'))

    @api.multi
    def unlink(self):
        raise UserError(_('ir.object should not be manipulated via ORM'))
