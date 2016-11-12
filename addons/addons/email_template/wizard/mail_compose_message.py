# -*- coding: utf-8 -*-
##############################################################################
#
#    OpenERP, Open Source Management Solution
#    Copyright (C) 2010-Today OpenERP SA (<http://www.openerp.com>)
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>
#
##############################################################################

import base64

import netsvc
from osv import osv
from osv import fields
from tools.translate import _
import tools


def _reopen(self, wizard_id, res_model, res_ids):
    return {'type': 'ir.actions.act_window',
            'view_mode': 'form',
            'view_type': 'form',
            'res_id': wizard_id,
            'res_model': self._name,
            'target': 'new',

            # save original model in context, otherwise
            # it will be lost on the action's context switch
            'context': {'mail.compose.target.model': res_model,
                        'mail.compose.target.ids': res_ids,}
    }

class mail_compose_message(osv.osv_memory):
    _inherit = 'mail.compose.message'

    def _get_templates(self, cr, uid, context=None):
        """
        Return Email Template of particular  Model.
        """
        if context is None:
            context = {}
        record_ids = []
        email_template= self.pool.get('email.template')
        model = False
        if context.get('message_id'):
            mail_message = self.pool.get('mail.message')
            message_data = mail_message.browse(cr, uid, int(context.get('message_id')), context)
            model = message_data.model
        elif context.get('mail.compose.target.model') or context.get('active_model'):
            model = context.get('mail.compose.target.model', context.get('active_model'))
        if model:
            record_ids = email_template.search(cr, uid, [('model', '=', model)])
            return email_template.name_get(cr, uid, record_ids, context) + [(False,'')]
        return []

    _columns = {
        'use_template': fields.boolean('Use Template'),
        'template_id': fields.selection(_get_templates, 'Template',
                                        size=-1 # means we want an int db column
                                        ),
        'model_id': fields.many2one('ir.model', 'Model'),
        'report': fields.many2one('ir.actions.report.xml', 'Report'),
        'report_base_name': fields.char('Base report name', size=128),
        'report_name_template': fields.char('Attached Report name template', size=128),
    }
    
    _defaults = {
        'template_id' : lambda self, cr, uid, context={} : context.get('mail.compose.template_id', False)          
    }

    def onchange_mail_server_id(self, cr, uid, ids, mail_server_id, context=None):
        if mail_server_id:
            mail_srv_obj = self.pool['ir.mail_server']
            srv = mail_srv_obj.browse(cr, uid, mail_server_id, context=context)
            return {'value': {'email_from': srv.smtp_user}}
        return False

    def on_change_template(self, cr, uid, ids, use_template, template_id, email_from=None, email_to=None, context=None):
        if context is None:
            context = {}
        values = {}
        if template_id:
            active_ids = context.get('active_ids', [])
            if len(active_ids) > 1:
                # use the original template values - to be rendered when actually sent
                # by super.send_mail()
                template = self.pool.get('email.template').browse(cr, uid, template_id, context)
                if template.body_html:
                    values['body_text'] = template.body_html
                    values['subtype'] = 'html'
                else:
                    values['body_text'] = template.body_text
                    values['subtype'] = 'plain'
                
                values['model_id'] = template.model_id.id or False
                values['report'] = template.report_template.id or False
                values['report_base_name'] = template.report_template.report_name
                values['report_name_template'] = template.report_name
                values['mail_server_id'] = template.mail_server_id.id or False
                values['auto_delete'] = template.auto_delete
                values['use_template'] = True
    
                values['email_from'] = template.email_from
                values['subject'] = template.subject
                values['email_to'] = template.email_to
                values['email_cc'] = template.email_cc
                values['email_bcc'] = template.email_bcc
                values['reply_to'] = template.reply_to
                
                template = self.pool.get('email.template').browse(cr, uid, template_id, context=context)
                
                # Add document attachments
                attachments = []
                for attach in template.attachment_ids:
                    # keep the bytes as fetched from the db, base64 encoded
                    attachments[attach.datas_fname] = attach.datas
    
                values['attachments'] = attachments  
                if values['attachments']:
                    attachment = values.pop('attachments')
                    attachment_obj = self.pool.get('ir.attachment')
                    att_ids = []
                    for fname, fcontent in attachment.iteritems():
                        data_attach = {
                            'name': fname,
                            'datas': fcontent,
                            'datas_fname': fname,
                            'description': fname,
                            'res_model' : self._name,
                            'res_id' : ids[0] if ids else False
                        }
                        att_ids.append(attachment_obj.create(cr, uid, data_attach))
                    values['attachment_ids'] = att_ids
            else:
                # in case of single document, render in place
            
                template = self.pool.get('email.template').browse(cr, uid, template_id, context)
                model = context.get('active_model')
                res_id = active_ids[0]
                if template.body_html:
                    values['body_text'] = self.render_template(cr, uid, template.body_html, model, res_id, context=context)
                    values['subtype'] = 'html'
                else:
                    values['body_text'] = self.render_template(cr, uid, template.body_text, model, res_id, context=context)
                    values['subtype'] = 'plain'
                
                values['model_id'] = template.model_id.id or False
                values['report'] = template.report_template.id or False
                values['report_base_name'] = template.report_template.report_name
                values['report_name_template'] = template.report_name
                values['mail_server_id'] = template.mail_server_id.id or False
                values['auto_delete'] = template.auto_delete
                values['use_template'] = False
    
                values['email_from'] = self.render_template(cr, uid, template.email_from, model, res_id, context=context)
                values['subject'] = self.render_template(cr, uid, template.subject, model, res_id, context=context)
                values['email_to'] = self.render_template(cr, uid, template.email_to, model, res_id, context=context)
                values['email_cc'] = self.render_template(cr, uid, template.email_cc, model, res_id, context=context)
                values['email_bcc'] = self.render_template(cr, uid, template.email_bcc, model, res_id, context=context)
                values['reply_to'] = self.render_template(cr, uid, template.reply_to, model, res_id, context=context)
                
                template = self.pool.get('email.template').browse(cr, uid, template_id, context=context)
                
                # Add document attachments
                attachments = {}
                for attach in template.attachment_ids:
                    # keep the bytes as fetched from the db, base64 encoded
                    attachments[attach.datas_fname] = attach.datas

                if values['report']:
                    report_name = self.render_template(cr, uid, values['report_name_template'], model, res_id, context=context)
                    report_service = 'report.' + values['report_base_name']                # Ensure report is rendered using template's language
                    ctx = context.copy()
                    service = netsvc.LocalService(report_service)
                    (result, format) = service.create(cr, uid, [res_id], {'model': model}, ctx)
                    result = base64.b64encode(result)
                    if not report_name:
                        report_name = report_service
                    ext = "." + format
                    if not report_name.endswith(ext):
                        report_name += ext
                    attachments[report_name] = result
    
                if attachments:
                    attachment_obj = self.pool.get('ir.attachment')
                    att_ids = []
                    for fname, fcontent in attachments.iteritems():
                        data_attach = {
                            'name': fname,
                            'datas': fcontent,
                            'datas_fname': fname,
                            'description': fname,
                            'res_model' : self._name,
                            'res_id' : ids[0] if ids else False
                        }
                        att_ids.append(attachment_obj.create(cr, uid, data_attach))
                    values['attachment_ids'] = att_ids
        else:
            values['use_template'] = False            

        return {'value': values}


    def template_toggle(self, cr, uid, ids, context=None):
        for record in self.browse(cr, uid, ids, context=context):
            had_template = record.use_template
            record.write({'use_template': not(had_template)})
            if had_template:
                # equivalent to choosing an empty template
                onchange_defaults = self.on_change_template(cr, uid, record.id, not(had_template),
                                                            False, email_from=record.email_from,
                                                            email_to=record.email_to, context=context)
                record.write(onchange_defaults['value'])
            return _reopen(self, record.id, 
                            context.get('mail.compose.target.model', context['active_model']),
                            context.get('mail.compose.target.ids', context['active_ids']))

    def save_as_template(self, cr, uid, ids, context=None):
        if context is None:
            context = {}
        email_template = self.pool.get('email.template')
        model_pool = self.pool.get('ir.model')
        for record in self.browse(cr, uid, ids, context=context):
            model = context.get('active_model') or record.model
            model_ids = model_pool.search(cr, uid, [('model', '=', model)])
            model_id = model_ids and model_ids[0] or False
            model_name = ''
            if model_id:
                model_name = model_pool.browse(cr, uid, model_id, context=context).name
            template_name = "%s: %s" % (model_name, tools.ustr(record.subject))
            values = {
                'name': template_name,
                'email_from': record.email_from or False,
                'subject': record.subject or False,
                'body_text': record.body_text or False,
                'email_to': record.email_to or False,
                'email_cc': record.email_cc or False,
                'email_bcc': record.email_bcc or False,
                'reply_to': record.reply_to or False,
                'attachment_ids': [(6, 0, [att.id for att in record.attachment_ids])],

                'model_id': record.model_id.id or False,
                'report_template': record.report.id or False,
                'report_name': record.report_name_template,
            }
            template_id = email_template.create(cr, uid, values, context=context)
            record.write({'template_id': template_id,
                          'use_template': True})

        # _reopen same wizard screen with new template preselected
        return _reopen(self, record.id, model, record.res_id)

    # override the basic implementation 
    def render_template(self, cr, uid, template, model, res_id, context=None):
        return self.pool.get('email.template').render_template(cr, uid, template, model, res_id, context=context)
        
    def send_mail(self, cr, uid, ids, context=None):
        assert ids and len(ids) == 1
        attachment_obj = self.pool.get('ir.attachment')
        context = context or {}
        
        active_ids = context.get('active_ids', [])
        active_model = context.get('active_model')
        if not active_model or not active_ids:
            raise osv.except_osv(_('Invalid action !'), 
                                 _('No active model! Please contact your administrator'))

        ec = self.browse(cr, uid, ids[0], context=context)
        
        values = {}
        values['subtype'] = 'html'
        values['body_text'] = ec.body_text
            
        values['email_from'] = ec.email_from
        values['subject'] = ec.subject
        values['email_to'] = ec.email_to
        values['email_cc'] = ec.email_cc
        values['email_bcc'] = ec.email_bcc
        values['reply_to'] = ec.reply_to

        if len(active_ids) == 1:
            context['send_now'] = True
            
        for res_id in active_ids:
            new_ec_id = self.copy(cr, uid, ec.id, context=context)
            new_ec = self.browse(cr, uid, new_ec_id, context=context)
            new_values = values.copy()
            
            attachments = {}
            if ec.report:
                report_name = self.render_template(cr, uid, ec.report_name_template, ec.model_id.model, res_id, context=context)
                report_service = 'report.' + ec.report_base_name                # Ensure report is rendered using template's language
                ctx = context.copy()
                service = netsvc.LocalService(report_service)
                (result, format) = service.create(cr, uid, [res_id], {'model': ec.model_id.model}, ctx)
                result = base64.b64encode(result)
                if not report_name:
                    report_name = report_service
                ext = "." + format
                if not report_name.endswith(ext):
                    report_name += ext
                attachments[report_name] = result

            # Add document attachments
            for attach in ec.attachment_ids:
                # keep the bytes as fetched from the db, base64 encoded
                attachments[attach.datas_fname] = attach.datas

            new_values['attachment_ids'] = []

            for fname, fcontent in attachments.iteritems():
                data_attach = {
                    'name': fname,
                    'datas': fcontent,
                    'datas_fname': fname,
                    'description': fname,
                    'res_model' : self._name,
                    'res_id' : new_ec.id,
                }
                new_values['attachment_ids'].append((4, attachment_obj.create(cr, uid, data_attach)))
                
            new_ec.write(new_values)

            ctx = context.copy()
            ctx['active_model'] = active_model
            ctx['active_ids'] = [res_id]
            ctx['mail.compose.message.mode'] = 'mass_mail'
            super(mail_compose_message, self).send_mail (cr, uid, [new_ec.id], context=ctx)

        return {'type': 'ir.actions.act_window_close'}
        
# vim:expandtab:smartindent:tabstop=4:softtabstop=4:shiftwidth=4:
