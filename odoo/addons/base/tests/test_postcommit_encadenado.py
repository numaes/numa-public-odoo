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

    def test_si_un_postcommit_falla_los_demas_corren_y_se_deshace_solo_lo_suyo(self):
        orden = []
        cr = self.registry.cursor()
        try:
            cr.execute("CREATE TEMP TABLE numa_prueba_postcommit (valor text)")
            cr.commit()

            def falla():
                cr.execute("INSERT INTO numa_prueba_postcommit VALUES ('de la que falla')")
                cr.postcommit.add(lambda: orden.append('anidado de la que falla'))
                raise ValueError('postcommit que falla')

            def anda():
                cr.execute("INSERT INTO numa_prueba_postcommit VALUES ('de la que anda')")
                cr.postcommit.add(lambda: orden.append('anidado de la que anda'))

            cr.postcommit.add(falla)
            cr.postcommit.add(anda)
            with self.assertLogs('odoo.sql_db', level='ERROR') as registro:
                cr.commit()  # no relanza: la transacción ya estaba confirmada
            self.assertIn('postcommit que falla', '\n'.join(registro.output))
            self.assertEqual(orden, ['anidado de la que anda'],
                             'lo que registró el postcommit que falló no corre; lo del otro sí')
            cr.execute("SELECT valor FROM numa_prueba_postcommit")
            self.assertEqual([fila[0] for fila in cr.fetchall()], ['de la que anda'],
                             'se deshizo sólo lo del postcommit que falló')
            self.assertFalse(cr.postcommit)
            self.assertEqual(cr.postcommit.data, {})
        finally:
            cr.rollback()
            cr.execute("DROP TABLE IF EXISTS numa_prueba_postcommit")
            cr.commit()
            cr.close()
