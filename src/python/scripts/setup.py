#!/usr/bin/env python

import django
import os
import sys
from optparse import OptionParser
from django.core.management import call_command
from django.db.utils import OperationalError

# load django context and settings, so we can use gatherer below
sys.path.append(os.path.dirname(os.path.realpath(__file__)) + "/../")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "smogtrac.settings")
django.setup()

from API.models import MeasurementDevice
from webui.models import Station, Area, Parser, Parameter

usage = "usage: %prog --addr AA:BB:CC:DD:EE:FF --code SPSP-001"
parser = OptionParser(usage = usage)
parser.add_option("--addr", dest="addr", help="The BT Address of the device")
parser.add_option("--code", dest="code", help="The code name to use with the device")
 
# process options
(opts, args) = parser.parse_args(sys.argv[1:])
if not opts.code or not opts.addr:
    parser.print_help()
    sys.exit(1)

try:
    MeasurementDevice.objects.filter(code=opts.code).first()
except django.db.utils.OperationalError as e:
    if 'no such table' in str(e):
        call_command('migrate')
    else:
        raise e

MeasurementDevice(setting = MeasurementDevice.Attributes.ADDR, value = opts.addr, code = opts.code).save()

'''
    Ensure that the required station exists.
'''
if not Station.objects.filter(code="SPSP-001").count():
    area = Area(name="Local area", city="Not specified")
    area.save()
    parser = Parser(name="spsp")
    parser.save()
    Station(
        name="Local station",
        street="Not specified",
        parser=parser,
        area=area,
        code="SPSP-001"
    ).save()
    # Also create handled parameters
    Parameter(name="PM10", label="PM10", norm="50", unit="μg/m³").save()
    Parameter(name="PRESSURE", label="Pressure", unit="hPa").save()
    Parameter(name="TEMPERATURE", label="Temperature", unit="°C").save()
    Parameter(name="HUMIDITY", label="Humidity", unit="Φ").save()
