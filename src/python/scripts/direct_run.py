#!/usr/bin/env python

import django
import os
import sys
from optparse import OptionParser

# load django context and settings, so we can use gatherer below
sys.path.append(os.path.dirname(os.path.realpath(__file__)) + "/../")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "smogtrac.settings")
django.setup()

from django.utils import timezone
from smogtrac.settings import DEVICE_CODE
from API.models import MeasurementDevice
from webui.models import Measurement, Station
from gatherer.parsers.spsp import SPSP


parser = OptionParser()
parser.add_option("--code", dest="code", default=DEVICE_CODE, help="The code name to use with the device")
parser.set_defaults()
(opts, args) = parser.parse_args(sys.argv[1:])

try:
    station = Station.objects.get(code = opts.code)
    MeasurementDevice.objects.get(setting = MeasurementDevice.Attributes.ADDR, code = opts.code)
except (Station.DoesNotExist, MeasurementDevice.DoesNotExist):
    print("No station and/or device setup found for code: %s." % opts.code)
    print("In order to setup the device please run the setup.py script.")
    print("In order to setup the station please go to the Admin part of the UI.")
    sys.exit(1)

last_read = Measurement.objects.filter(station=station).order_by('date').last()
start_time = timezone.now()

parser = SPSP('PM10', station = station)
while not last_read or last_read.date < start_time - timezone.timedelta(minutes=5):
    parser.run()
    last_read = Measurement.objects.order_by('date').last()

parser.build_aggregates()
parser.cleanup()
