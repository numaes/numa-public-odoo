# -*- coding: utf-8 -*-
"""Postcommits encadenados de `Cursor.commit` (odoo/sql_db.py): por niveles, con un commit entre nivel
y nivel, para que lo que hace un postcommit no quede para la transacción siguiente ni la arruine.

El commit reemplazaba el objeto `postcommit` antes de correr cada nivel: un callback que leía
`cr.postcommit.data` encontraba uno nuevo y vacío. Así el `notify()` del bus no mandaba el NOTIFY imbus y
ninguna notificación commiteada llegaba en tiempo real (medido en prtest, sep-2026).
"""
from odoo.tests import common


@common.tagged('post_install', '-at_install')
class TestPostcommitEncadenado(common.TransactionCase):

    def test_los_callbacks_ven_la_data_que_se_les_dejo(self):
        vistos = []
        with self.registry.cursor() as cr:
            cr.postcommit.data['numa.prueba'] = 'dato'
            cr.postcommit.add(lambda: vistos.append(cr.postcommit.data.get('numa.prueba')))
        self.assertEqual(vistos, ['dato'])

    def test_lo_registrado_en_un_nivel_corre_despues_del_nivel_y_la_data_se_limpia(self):
        orden = []
        cr = self.registry.cursor()
        try:
            def anidado():
                orden.append('anidado')

            def primero():
                orden.append('primero')
                cr.postcommit.add(anidado)

            cr.postcommit.add(primero)
            cr.postcommit.add(lambda: orden.append('segundo'))
            cr.postcommit.data['numa.prueba'] = 1
            cr.commit()
            self.assertEqual(orden, ['primero', 'segundo', 'anidado'])
            self.assertFalse(cr.postcommit, 'no quedan funciones pendientes')
            self.assertEqual(cr.postcommit.data, {}, 'la data se limpia al terminar, como Callbacks.run()')
        finally:
            cr.close()

    def test_si_un_nivel_falla_se_revierte_y_no_corren_los_siguientes(self):
        orden = []
        cr = self.registry.cursor()
        try:
            def anidado():
                orden.append('anidado')

            def falla():
                cr.postcommit.add(anidado)
                raise ValueError('postcommit que falla')

            cr.postcommit.add(falla)
            with self.assertRaises(ValueError):
                cr.commit()
            self.assertEqual(orden, [], 'lo registrado por el nivel que falló no corre')
            self.assertFalse(cr.postcommit)
            self.assertEqual(cr.postcommit.data, {})
        finally:
            cr.close()
