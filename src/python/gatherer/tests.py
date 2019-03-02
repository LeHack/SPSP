from django.test import TestCase
from gatherer.service import Manager


class GathererTest(TestCase):

#     def testForecastWorker(self):
#         worker = ForecastWorker()
#         worker.run()
#         json = worker.__getattribute__("json")
#         self.assertEqual(json["dane"]["city"]["ci_name"], "krakow")

    """
    Run Workers and populate database
    """
    def testManager(self):
        manager = Manager()
        manager.run_all()