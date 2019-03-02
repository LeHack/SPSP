#!/usr/bin/env python

import django
import os
import sys

# load django context and settings, so we can use gatherer below
sys.path.append(os.path.dirname(os.path.realpath(__file__)) + "/../")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "smogtrac.settings")
django.setup()

from webui.models import Measurement, Station

sample_size = 10
result = {}
summator = {}
for m in Measurement.objects.filter(station=Station.objects.get(code="SPSP")).order_by('date').all():
    if m.type.name not in summator:
        summator[m.type.name] = {
            'last_store': m.date.strftime('%H:%M'),
            'values': [],
        }

    # trim older data
    sumlen = len(summator[m.type.name]['values'])
    if sumlen > sample_size - 1:
        summator[m.type.name]['values'] = summator[m.type.name]['values'][sumlen - sample_size - 1:]

    # calculate the rolling average
    avg = m.value
    for d in summator[m.type.name]['values']:
        avg += d
    avg /= len(summator[m.type.name]['values']) + 1

    # store it
    summator[m.type.name]['values'].append(avg)

    # check if it's time to store to the output
    if summator[m.type.name]['last_store'] != m.date.strftime('%H:%M'):
        if m.date.strftime('%Y-%m-%d %H:%M') not in result:
            result[m.date.strftime('%Y-%m-%d %H:%M')] = {}
        result[m.date.strftime('%Y-%m-%d %H:%M')][m.type.name] = int(avg)
        summator[m.type.name]['last_store'] = m.date.strftime('%H:%M')

for d in sorted(result.keys()):
    print("%s\t%d\t%d\t%d\t%d" % (d, result[d]["PM10"], result[d]["TEMPERATURE"], result[d]["HUMIDITY"], result[d]["PRESSURE"]))
