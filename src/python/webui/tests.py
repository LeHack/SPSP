import datetime
import pytz

from django.test import TestCase
from requests.packages.urllib3.util.url import Url

from .models import Station, Measurement, Parameter, Area, Parser


class MeasurementMockup(TestCase):

    def createMeta(self):
        # Start by flushing the current data
        Area.objects.all().delete()
        Parameter.objects.all().delete()
        Parser.objects.all().delete()

        # Create default Areas
        a_nh = Area(name="Nowa Huta", city="Kraków")
        a_nh.save()
        a_ce = Area(name="Centrum",   city="Kraków")
        a_ce.save()
        a_ku = Area(name="Kurdwanów", city="Kraków")
        a_ku.save()

        # Default parser
        wios = Parser(name="wios_krakow", url="http://monitoring.krakow.pios.gov.pl/dane-pomiarowe/pobierz")
        wios.save()

        # Stations
        Station(
            name="Kurdwanów",
            code="Kurdwanow",
            street="Bujaka",
            area=a_ku,
            parser=wios
        ).save()

        Station(
            name="Nowa Huta",
            code="NowaHuta",
            street="Bulwarowa",
            area=a_nh,
            parser=wios
        ).save()

        Station(
            name="Aleja Krasińskiego",
            code="Krasinskiego",
            street="Aleja Krasińskiego",
            area=a_ce,
            parser=wios
        ).save()

        # Parameters
        Parameter(
            name="PM10",
            description="Pył zawieszony jest mieszaniną niezwykle małych cząstek. Pyłem zawieszonym PM10 są wszystkie cząstki mniejsze niż 10µm. Zanieczyszczenia pyłowe mogą osiągać różne rozmiary oraz kształty. Ponadto posiadają zdolność do adsorpcji na swojej powierzchni innych, bardzo szkodliwych zanieczyszczeń (dioksyn i furanów, metali ciężkich, czy wielopierścieniowych węglowodorów aromatycznych – m.in. benzo(a)pirenu). Pyły zawieszone przede wszystkim emitowane są bezpośrednio a takich źródeł jak pożary, unoszenia się pyłu z palców budów, dróg niepokrytych asfaltem, procesów spalania.",
            norm=50
        ).save()

        Parameter(
            name="PM2.5",
            description="Pył zawieszony jest mieszaniną niezwykle małych cząstek. Pyłem zawieszonym PM2,5 są wszystkie cząstki mniejsze niż 2,5µm. Zanieczyszczenia pyłowe mogą osiągać różne rozmiary oraz kształty. Ponadto posiadają zdolność do adsorpcji na swojej powierzchni innych, bardzo szkodliwych zanieczyszczeń (dioksyn i furanów, metali ciężkich, czy wielopierścieniowych węglowodorów aromatycznych – m.in. benzo(a)pirenu). Pyły zawieszone przede wszystkim emitowane są bezpośrednio a takich źródeł jak pożary, unoszenia się pyłu z palców budów, dróg niepokrytych asfaltem, procesów spalania.",
            norm=25
        ).save()

    def createData(self):
        # Clear out the table
        Measurement.objects.all().delete()

        st_ku = Station.objects.get(name="Kurdwanów")
        st_nh = Station.objects.get(name="Nowa Huta")
        st_ak = Station.objects.get(name="Aleja Krasińskiego")

        date = pytz.timezone('CET').localize(datetime.datetime(2016, 12, 3, 1, 0, 0))
        # Copied from WIOŚ
        data = {
            st_ku: [20, 25, 31, 21, 25, 21, 14, 22, 18, 18, 26, 20, 20, 16, 23, 32, 27, 30, 38, 46, 49, 35],
            st_nh: [20, 26, 18, 20, 18, 15, 17, 16, 17, 15, 16, 17, 16, 16, 12, 18, 30, 27, 32, 30, 40, 24],
            st_ak: [36, 33, 29, 25, 22, 17, 21, 19, 20, 24, 31, 24, 21, 39, 46, 50, 64, 66, 75, 77, 54, 67]
        }
        for i in range(1, 22):
            for st in data:
                Measurement(date=date, value=data[st][i], station=st, type=Parameter.objects.get(name="PM10")).save()
            date += datetime.timedelta(hours=1)
