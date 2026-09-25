from odoo.tests import TransactionCase, tagged


@tagged('post_install', '-at_install')
class TestChartTemplateCodeSize(TransactionCase):
    """A translated journal code must still fit the journal's code field (size 7).

    The chart translates the journal codes into the company's language, and some
    translations are longer than the field: es_419 turned MISC into MISCELÁNEO, so a
    company in Spanish (Latin America) -- es_AR among them -- could not get its chart,
    and a database created in Spanish for Argentina did not start.
    """

    def _company_in(self, lang):
        self.env['res.lang']._activate_lang(lang)
        company = self.env['res.company'].create({'name': f'Company {lang}'})
        company.partner_id.lang = lang
        self.env['account.chart.template'].try_loading('generic_coa', company, install_demo=False)
        return company

    def _code(self, company, journal_type_code):
        journal = self.env['account.chart.template'].with_company(company).ref(journal_type_code)
        return journal.code

    def test_a_company_in_argentine_spanish_gets_its_chart(self):
        company = self._company_in('es_AR')
        self.assertEqual(self._code(company, 'general'), 'VARIOS')
        self.assertEqual(self._code(company, 'purchase'), 'FACTURA')

    def test_a_code_translated_too_long_keeps_the_original(self):
        # Finnish translates MISC as SEKALAISET (10 characters): kept out, and said.
        with self.assertLogs('odoo.addons.account.models.chart_template', 'WARNING') as logs:
            company = self._company_in('fi_FI')
        self.assertIn('SEKALAISET', logs.output[0])
        self.assertEqual(self._code(company, 'general'), 'MISC')
