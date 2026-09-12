# -*- coding: utf-8 -*-
"""NOTIFY imbus con los postcommits encadenados de `Cursor.commit` (odoo/sql_db.py).

El commit corre los postcommits por niveles, con un commit entre nivel y nivel. Un postcommit que
notifica sobre el mismo cursor tiene que avisar DESPUÉS de que se crean sus filas, no sumarse al aviso
del nivel en curso. Se simulan los niveles a mano: en un TransactionCase no se puede commitear.
"""
from unittest.mock import patch

from odoo.tests import TransactionCase, tagged


@tagged('post_install', '-at_install')
class TestNotifyConPostcommitsEncadenados(TransactionCase):

    def _correr_nivel(self):
        """Lo que hace Cursor.commit por nivel: las funciones pendientes y después el flush."""
        nivel = list(self.env.cr.postcommit._funcs)
        self.env.cr.postcommit._funcs.clear()
        for func in nivel:
            func()
        self.env.cr.precommit.run()

    def test_cada_aviso_sale_despues_de_crear_sus_filas(self):
        Bus = self.env['bus.bus']
        Bus.search([]).unlink()
        avisos = []

        def _payloads(canales):
            avisos.append(([c[1] for c in canales], Bus.search_count([])))
            return []

        with patch('odoo.addons.bus.models.bus.get_notify_payloads', side_effect=_payloads):
            # Un postcommit registrado ANTES de la primera notificación, que notifica sobre este cursor.
            self.env.cr.postcommit.add(lambda: Bus._sendone('canal B', 'prueba', {}))
            Bus._sendone('canal A', 'prueba', {})
            Bus._sendone('canal A', 'prueba', {})
            self.env.cr.precommit.run()   # commit de la transacción: filas de A
            self._correr_nivel()          # nivel 1: el postcommit manda B y avisa A; el flush crea B
            self._correr_nivel()          # nivel 2: aviso de B
        self.assertEqual(avisos, [(['canal A'], 2), (['canal B'], 3)],
                         'cada aviso con sus canales y con sus filas ya creadas')

    def test_sin_postcommits_anidados_un_solo_aviso_con_todos_los_canales(self):
        Bus = self.env['bus.bus']
        avisos = []
        with patch('odoo.addons.bus.models.bus.get_notify_payloads',
                   side_effect=lambda canales: avisos.append([c[1] for c in canales]) or []):
            Bus._sendone('canal 1', 'prueba 1', {})
            Bus._sendone('canal 2', 'prueba 2', {})
            Bus._sendone('canal 1', 'prueba 3', {})
            self.env.cr.precommit.run()
            self.env.cr.postcommit.run()
        self.assertEqual(avisos, [['canal 1', 'canal 2']])
