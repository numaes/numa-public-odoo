# -*- coding: utf-8 -*-
from odoo import api, fields, models, exceptions, _

import logging
_logger = logging.getLogger(__name__)

MODULE_UNINSTALL_FLAG = '_force_unlink'


class IrObject(models.Model):
    _name = 'ir.object'
    _description = '''
    Base of all objects
    '''

    object_model_id = fields.Many2one('ir.model', 'Object model', required=True)
    object_state_id = fields.Many2one('ir.state.definition', 'Current state')
    create_uid = fields.Many2one('res.users', 'Created by')
    create_date = fields.Datetime('Created on')
    write_uid = fields.Many2one('res.users', 'Last write by')
    write_date = fields.Datetime('Last write on')

    def as_own_object(self):
        self.ensure_one()

        modelModel = self.env[self.object_model_id.name]
        return modelModel.browse(self.id).exists()

    def valid_states(self):
        self.ensure_one()

        stateDefinitionModel = self.env['ir.state.definition']

        return stateDefinitionModel.search([('model_id', '=', self.object_model_id.id)])

    def set_object_state(self, new_state_code):
        models = {}
        stateDefinitionModel = self.env['ir.state.definition']

        for object in self:
            if object.object_model_id._name not in models:
                models[object.object_model_id._name] = self.env[object.object_model_id._name]

            newValidState = stateDefinitionModel.search([('model_id', '=', self.object_model_id.id),
                                                         ('code', '=', new_state_code)], limit=1)
            if newValidState:
                self.object_state_id = newValidState.id
            else:
                raise exceptions.ValidationError(_('State code %(code)s not found for model %(model_name)s') %
                                                 {'code': new_state_code, 'model_name': object.object_model_id.name})

