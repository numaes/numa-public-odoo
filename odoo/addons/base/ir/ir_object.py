# -*- coding: utf-8 -*-
# See LICENSE file for full copyright and licensing details.

from odoo import fields, models, _
from odoo.exceptions import ValidationError
import logging

_logger = logging.getLogger(__name__)


class InstanceState(models.Model):
    _name = 'ir.instance.state'
    _rec_name = 'code'

    base_model_id = fields.Many2one('ir.model', 'Model', required=True)
    code = fields.Char('State code', help='Code to be used on programing to identify the state', required=True)
    name = fields.Char('Name', translate=True, required=True,
                       help='Human readable state name')


class Instance(models.Model):
    _name = 'ir.instance'

    base_model_id = fields.Many2one('ir.model', 'Model', required=True)
    create_date = fields.Date('Created on', required=True)
    created_uid = fields.Many2one('res.users', 'Created by', required=True)
    write_date = fields.Date('Last modified on', required=True)
    write_uid = fields.Many2one('res.users', 'Last modified by', required=True)
    current_state_id = fields.Many2one('ir.instance_state', 'State')

    def change_state_to(self, new_state, current_state=None):
        stateModel = self.env['ir.instance_state']

        for instance in self:
            if current_state and instance.current_state_id.code != current_state:
                raise ValidationError(_('Invalid state transition: current_state is not %s') % current_state)

            targetState = stateModel.search([('base_model_id', '=', instance.base_model_id.id), ('code', '=', new_state)])
            if not targetState or len(targetState) > 1:
                raise ValidationError(_('Invalid state transition: new_state("%s") does not exists in model %s') %
                                      (new_state, instance.name))

            instance.current_state_id = targetState
