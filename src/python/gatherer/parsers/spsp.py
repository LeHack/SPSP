import logging
from django.utils import timezone
from django.utils.timezone import datetime, timedelta
from functools import reduce

from API.BTHandler import BTHandler
from API.SPSP import SpspAPI
from gatherer.service import AbstractWorker
from webui.models import Measurement, Measurement15mAggr, Parameter


class SPSP(AbstractWorker):
    logger     = logging.getLogger('gatherer.parsers.spsp')
    station    = None
    pm_type    = None
    day        = None
    dev_bootup = None

    def __init__(self, pm_type, day = None, station = None):
        super().__init__()

        self.spsp        = SpspAPI(device_code=station.code)
        self.station     = station
        self.param_types = {
            'pm10':         Parameter.objects.get(name='PM10'),
            'pressure':     Parameter.objects.get(name='PRESSURE'),
            'temperature':  Parameter.objects.get(name='TEMPERATURE'),
            'humidity':     Parameter.objects.get(name='HUMIDITY'),
        }

    def gather(self):
        self.logger.info("Starting archiving operations")
        # First find the devices current epoh
        self.dev_bootup = self.spsp.get_time_of_bootup()
        read_freq = self.spsp.settings.get_measurement_frequency()
        # Now get the date of the lat measurement
        last_measure = Measurement.objects.filter(
            station=self.station
        ).order_by('date').last()

        start_offset = None
        if not last_measure or self.dev_bootup > last_measure.date:
            start_offset = 1
        else:
            start_offset = int(last_measure.date.timestamp()) - int(self.dev_bootup.timestamp()) + read_freq

        self.logger.info("Calculated the device bootup time: " + datetime.strftime(self.dev_bootup, "%Y-%m-%d %H:%M:%S"))
        self.logger.debug("Using start offset: " + str(start_offset))

        output = []
        offset = start_offset

        # get the data, 500 records at a time
        while offset and len(output) < 500 and offset < int(timezone.now().timestamp() - self.dev_bootup.timestamp()):
            data = None
            try:
                data = self.spsp.get_archived_reading(offset)
            except BTHandler.CommandTimeout:
                self.logger.error("Warning, could not get stored for offset: %d" % offset)
                self.logger.error("Trying to reconnect...")
                # and retry
                try:
                    self.spsp.disconnect()
                    self.spsp.connect()
                    data = self.spsp.get_archived_reading(offset)
                except Exception as e:
                    self.logger.critical("Failed twice, giving up, trying to store what we've got so far, final failure reason: " + repr(e))
                    break

            if data:
                output += data
                offset = data[-1]['timestamp'] + read_freq
            else:
                # try finding a new offset from the place we finished at
                self.logger.error("Timer drift detected at " + str(offset))
                offset = self.spsp.find_starting_offset(offset)

        self.logger.debug("Fetching done.")
        return output

    def process(self, data):
        self.logger.debug("Got %d records for processing..." % len(data))
        measurement_list = []
        cache = {}
        for r in data:
            local_time = (self.dev_bootup + timedelta(seconds = int(r['timestamp']))).astimezone()

            for data_type in ('pressure', 'pm10', 'temperature', 'humidity'):
                if data_type not in cache:
                    # init cache with a valid set of values
                    if self.__is_valid(data_type, r[data_type], r[data_type]):
                        cache[data_type] = r[data_type]
                    else:
                        self.logger.warning("Skipping invalid reading: %s = %s [%s]" % (data_type, str(r[data_type]), str(local_time)))
                        break

                if not self.__is_valid(data_type, r[data_type], cache[data_type]):
                    self.logger.warning("Skipping invalid reading: %s = %s [%s]" % (data_type, str(r[data_type]), str(local_time)))
                    break

                measurement_list.append(
                    Measurement(date=local_time, value=r[data_type], station=self.station, type=self.param_types[data_type])
                )
                # update cache
                cache[data_type] = r[data_type]

        self.logger.debug("Storing data...")
        Measurement.objects.bulk_create(measurement_list)
        self.logger.info("All done.")

    def build_aggregates(self):
        for param in Parameter.objects.all():
            self.aggregate(param)

    def aggregate(self, param):
        # start by checking the aggregate table
        last_entry = Measurement15mAggr.objects.filter(type = param).order_by('date').last()
        filters = { 'type': param }
        if last_entry:
            filters['date__gt'] = last_entry.date
        raw_data = Measurement.objects.filter(**filters).order_by('date').all()
        if not raw_data:
            return

        rolling_avg = []
        agr_entries = []
        cur_quad = last_quad = None

        self.logger.debug("Found %d %s records to aggregate." % (len(raw_data), str(param)))
        # PROFILE ME!
        for entry in raw_data:
            last_quad = cur_quad
            for quad in [15, 30, 45, 60]:
                if entry.date.minute < quad:
                    cur_quad = quad
                    break

            # update rolling avg
            rolling_avg.append(int(entry.value))
            if not last_quad or last_quad == cur_quad:
                continue

            avg_val = int(reduce(lambda a,b: a + b, rolling_avg)/len(rolling_avg))
            rolling_avg = [avg_val]

            agr_entries.append(
                Measurement15mAggr(
                    date = entry.date,
                    date_s = entry.date.date(),
                    value = avg_val,
                    type = entry.type,
                    station = entry.station
                )
            )

        if agr_entries:
            Measurement15mAggr.objects.bulk_create(agr_entries)

        return

    def cleanup(self):
        self.spsp.cleanup()

    def __is_valid(self, data_type, value, prev_value):
        checks = {
            'pressure':     lambda v,c: c - 20 < v < c + 20 and 970 < v < 1050,
            'pm10':         lambda v,c: c - 50 < v < c + 50,
            'temperature':  lambda v,c: c - 10 < v < c + 10,
            'humidity':     lambda v,c: c - 20 < v < c + 20,
        }

        return checks[data_type](value, prev_value)
