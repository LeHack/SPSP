import json
import logging
import pygal

from django.http import JsonResponse, HttpResponse
from django.shortcuts import render
from django.utils import dateparse, timezone

from API.SPSP import SpspAPI, SpspSettings
from smogtrac.settings import DEVICE_CODE
from gatherer.models import Gatherer
from gatherer.service import Manager
from .models import Area, Measurement15mAggr, Parameter, Station


def index(request):
    # fetch params and set defaults
    last_measurement = Measurement15mAggr.objects.order_by('date').last()
    if last_measurement:
        day = last_measurement.date
    else:
        day = timezone.now()
    if 'date' in request.POST:
        temp = dateparse.parse_date(request.POST['date'])
        if temp is not None:
            day = temp

    filters = {"date__date": day}
    stations = [Station.objects.get(code = DEVICE_CODE)]

    data = {}
    avail_params = []
    found_params = []
    for param in Parameter.objects.all():
        avail_params.append({
            'id': param.pk,
            'name': param.name,
            'label': param.label,
            'unit': param.unit,
        })
        parsed = getData(param, filters)
        if parsed:
            found_params.append({
                'id': param.pk,
                'name': param.name,
                'label': param.label,
                'unit': param.unit,
            })
            for p in parsed:
                if not p['date'] in data:
                    data[p['date']] = {
                        'date': p['date']
                    }
                data[p['date']][p['type']] = p['value']

    # attach glyph-icons
    icon_map = {
        'PM10': 'glyphicon-cloud',
        'PM2.5': 'glyphicon-cloud',
        'PRESSURE': 'glyphicon-circle-arrow-down',
        'HUMIDITY': 'glyphicon-tint',
        'TEMPERATURE': 'glyphicon-fire',
    }
    for p in found_params:
        if p['name'] in icon_map:
            icon = icon_map[p['name']]
        else:
            icon = 'glyphicon-flag'
        p['icon'] = icon

    params = {
        "selected": {
            "date": day.strftime('%Y-%m-%d'),
        },
        "chart": {
            'type': avail_params[0]['id'] if avail_params else 0,
            'range': 'last24h',
        },
        "found": found_params,
        "available": avail_params,
        "ranges": get_ranges(),
    }

    context = {
        'data': [data[date] for date in sorted(data.keys())],
        'params': params,
        'stations': stations,
    }
    return render(request, 'webui/index.html', context)


def startDataRefresh(request, area, pm_type):
    # if there is no other process running
    status = "busy"
    stations = Station.objects.filter(area=Area.objects.get(name=area)).all() if area != 'dowolne' else None
    if Manager.isReady():
        Manager(pm_type=pm_type.lower(), stations=stations, run_by=Gatherer.UI).fireAndForget()
        status = "started"

    return JsonResponse({"refresh": status})


def checkDataRefresh(request):
    # if there is no other process running
    status = "working"
    if Manager.isReady():
        status = "ready"

    return JsonResponse({"refresh": status})


def getChart(request, paramid, dateRange):
    logger = logging.getLogger('webui.view.getChart')
    param = Parameter.objects.get(pk=paramid)
    filters = {"date__gt": getRangeDate(dateRange)}
    logger.debug("Got params: " + repr(filters))

    rangeLabel = None
    rangeInd = 0
    showXlabelEvery = 5
    for r in get_ranges():
        rangeInd += 1
        if r['id'] == dateRange:
            rangeLabel = r['label']
            break

    getDataParams = {
        'filters': filters,
    }
    if rangeInd > 3:
        getDataParams['datestr'] = '%m-%d'
        getDataParams['rollavg_range'] = 1440  # 24h
        showXlabelEvery = 1
    elif rangeInd > 2:
        getDataParams['datestr'] = '%m-%d %H:00'
        getDataParams['rollavg_range'] = 360  # 6h
        showXlabelEvery = 2
    elif rangeInd > 1:
        getDataParams['datestr'] = '%m-%d %H:00'
        getDataParams['rollavg_range'] = 180  # 3h
        showXlabelEvery = 4

    parsed = getData(param, **getDataParams)
    if not parsed:
        return JsonResponse({"chart": "/static/images/no_chart.png"})
    dates = []

    # parsed[entry.date][entry.station.code][entry.type.id]
    data_set = []
    extremes = {
        'min': None,
        'max': None,
        'range': 1
    }
    for d in parsed:
        val = d['value']['raw']
        if extremes['min'] is None:
            extremes['min'] = val
        if extremes['max'] is None:
            extremes['max'] = val
        if val < extremes['min']:
            extremes['min'] = val
        if val > extremes['max']:
            extremes['max'] = val

        dates.append(d['date'])
        data_set.append(val)

    extremes['range'] = int(.5 * (extremes['max'] - extremes['min']))
    if extremes['range'] <= 1:
        extremes['range'] = 2

    chart = pygal.Line(
        x_label_rotation=35,
        x_labels_major_every=showXlabelEvery,
        show_minor_x_labels=False,
        show_dots=False,
        show_legend=False,
        order_min=.1,
        range=(extremes['min'] - extremes['range'], extremes['max'] + extremes['range'])
    )

    chart.title = '%s, %s [%s]' % (rangeLabel, param.label, param.unit)
    chart.x_labels = dates
    chart.add(param.label, data_set)

    r = JsonResponse({"chart": chart.render_data_uri()})
    # don't cache this
    r['Cache-Control'] = 'no-cache'

    return r

def getSettings(request):
    logger = logging.getLogger('webui.view.getSettings')
    force = request.GET['force'] if 'force' in request.GET else False
    logger.debug("Fetching settings, force: " + str(force))

    api = SpspAPI(device_code = DEVICE_CODE)
    if force:
        api.settings.reset_cache()

    settings = {
        'pm10norm': 0,
        'mFreq': 0,
        'dispTime': 0,
        'sampleSize': 0,
        'pressRef': 0,
        'btName': '',
    }
    for p in settings:
        settings[p] = get_api_map()[p]['get'](api)
    api.cleanup()

    return JsonResponse({
        "settings": settings
    })

def updateSettings(request):
    logger = logging.getLogger('webui.view.updateSettings')
    settings = json.loads(request.POST['settings'] or '{}')
    logger.debug("Updating settings: %s" % repr(settings))

    api = SpspAPI(device_code = DEVICE_CODE)
    errors = {}
    for p in settings:
        new_v     = settings[p]
        current_v = get_api_map()[p]['get'](api)
        if new_v != str(current_v):
            try:
                get_api_map()[p]['set'](api, new_v)
            except SpspSettings.ValidationError as e:
                errors[p] = str(e)
    api.cleanup()

    if errors:
        return JsonResponse(data={
            'status': 'ERROR',
            'errors': errors
        }, status=400)

    return HttpResponse(status = 200)


def getLatestReadings(request):
    logger = logging.getLogger('webui.view.getLatestReadings')
    api = SpspAPI(device_code = DEVICE_CODE)
    record = api.get_current_reading()
    logger.debug("Got record: " + repr(record))
    data = {
        'PM10':         record['pm10'],
        'PRESSURE':     record['pressure'],
        'HUMIDITY':     record['humidity'],
        'TEMPERATURE':  record['temperature'],
        'readTime':     record['datetime'].strftime("%Y-%m-%d %H:%M:%S")
    }
    api.cleanup()

    return JsonResponse({
        "readings": data
    })


def getData(param, filters, datestr='%H:%M', rollavg_range=15):
    logger = logging.getLogger('webui.view.getData')
    logger.debug("Fetching data for %s using filters: %s" % (str(param), repr(filters)))
    out = []

    rolling_avg = []
    for entry in Measurement15mAggr.objects.filter(type = param, **filters).order_by('date').all():
        if rollavg_range > 15 and (not rolling_avg or (entry.date - rolling_avg[0].date).total_seconds() < rollavg_range * 60):
            rolling_avg.append(entry)
            continue

        value = int(entry.value)
        if rolling_avg:
            tmp = 0
            for r in rolling_avg:
                tmp += r.value
            value = int(tmp/len(rolling_avg))
            rolling_avg = [entry]

        record = {
            'date': timezone.localtime(entry.date).strftime(datestr),
            'type': entry.type.pk,
            'value': {
                'raw' : value,
            }
        }
        if entry.type.norm:
            norm = int(entry.value * 100 / entry.type.norm)
            record['value']['class'] = get_class_for(norm)
            if norm > 0:
                record['value']['norm'] = "%d" % norm

        out.append(record)

    logger.debug("Data ready: %d" % len(out))
    return out


def get_class_for(norm):
    if (norm > 700):
        cls = "alarm"
    elif (norm > 400):
        cls = "dangr" # danger is a bootstrap class, so I8E
    elif (norm > 200):
        cls = "warn"
    elif (norm > 75):
        cls = "notice"
    else:
        cls = "ok"
    return cls

def get_api_map():
    return {
        'pm10norm': {
            'get': lambda api: api.settings.get_pm10_norm(),
            'set': lambda api, v: api.settings.set_pm10_norm(v)
        },
        'mFreq': {
            'get': lambda api: api.settings.get_measurement_frequency(),
            'set': lambda api, v: api.settings.set_measurement_frequency(v)
        },
        'dispTime': {
            'get': lambda api: api.settings.get_display_timeout(),
            'set': lambda api, v: api.settings.set_display_timeout(v)
        },
        'sampleSize': {
            'get': lambda api: api.settings.get_sampling_size(),
            'set': lambda api, v: api.settings.set_sampling_size(v)
        },
        'pressRef': {
            'get': lambda api: api.settings.get_pressure_reference_value(),
            'set': lambda api, v: api.settings.set_pressure_reference_value(v)
        },
        'btName': {
            'get': lambda api: api.settings.get_bluetooth_name(),
            'set': lambda api, v: api.settings.set_bluetooth_name(v)
        },
    }

def get_ranges():
    return [
        { "id": 'last24h', "label": "Ostatnie 24 godziny" },
        { "id": 'last7d',  "label": "Ostatnie 7 dni" },
        { "id": 'last14d', "label": "Ostatnie 14 dni" },
        { "id": 'last30d', "label": "Ostatnie 30 dni" },
    ]

def getRangeDate(dateRange):
    ranges = {
        'last24h': lambda: timezone.now() - timezone.timedelta(hours=24),
        'last7d':  lambda: timezone.now() - timezone.timedelta(days=7),
        'last14d': lambda: timezone.now() - timezone.timedelta(days=14),
        'last30d': lambda: timezone.now() - timezone.timedelta(days=30),
    }
    return ranges[dateRange]()
