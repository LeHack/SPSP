#!/usr/bin/env python

import django
import os
import sys
from optparse import OptionParser

# load django context and settings, so we can use gatherer below
sys.path.append(os.path.dirname(os.path.realpath(__file__)) + "/../")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "smogtrac.settings")
django.setup()

from API.models import MeasurementDevice

usage = "usage: %prog --addr AA:BB:CC:DD:EE:FF --code SPSP-001"
parser = OptionParser(usage = usage)
parser.add_option("--addr", dest="addr", help="The BT Address of the device")
parser.add_option("--code", dest="code", help="The code name to use with the device")
 
# process options
(opts, args) = parser.parse_args(sys.argv[1:])
if not opts.code or not opts.addr:
    parser.print_help()
    sys.exit(1)

MeasurementDevice(setting = MeasurementDevice.Attributes.ADDR, value = opts.addr, code = opts.code).save()
