import logging
from API.BTHandler import BTHandler
from API.models import MeasurementDevice
from django.utils import timezone


class SpspSettings:
    logger       = logging.getLogger('API.SpspSettings')
    bt_handler   = None
    device_code  = None

    class ValidationError(BaseException):
        pass

    def set_bt_handler(self, bt):
        self.bt_handler = bt

    def set_device_code(self, code):
        self.device_code = code

    def reset_cache(self):
        # drop the existing cache, if any
        MeasurementDevice.clear_settings(self.device_code)

    def __using_cache(self, setting, method, force_refresh=False, set_value=None):
        # load or initialize the setting from cache
        cache = MeasurementDevice.objects.filter(code = self.device_code, setting = setting).order_by('modified').last()

        out = None
        if not set_value and not force_refresh and cache and cache.modified < timezone.now() + timezone.timedelta(hours=24):
            out = cache.value
        else:
            if set_value:
                method(set_value)
                out = set_value
            else:
                out = method()

            # update cache
            self.logger.debug("Updating cached value for %s = %s" % (str(setting), str(out)))
            if not cache:
                cache = MeasurementDevice(code = self.device_code, setting = setting)
            cache.value = out
            cache.save()

        return out

    def get_pm10_norm(self, force_refresh=False):
        return int(self.__using_cache(
            setting = MeasurementDevice.Settings.PM10NORM,
            method  = lambda: self.bt_handler.fetch_value("GETCFGPM10"),
            force_refresh = force_refresh,
        ))

    def set_pm10_norm(self, value):
        # TODO: Check device and switch back to <
        if not (SpspSettings.__isnum__(value) and 0 <= int(value) < 256):
            raise self.ValidationError("Wartość normy PM10 musi być liczbą w zakresie 1 do 255 [ug/m3]")
        out = self.__using_cache(
            setting = MeasurementDevice.Settings.PM10NORM,
            method  = lambda val: self.bt_handler.fetch_value("SETCFGPM10", val),
            set_value = value
        )
        if out == 2**64:
            raise self.ValidationError("Błąd zapisu w pamięci urządzenia: niepoprawna wartość.")
        return out

    def get_measurement_frequency(self, force_refresh=False):
        return int(self.__using_cache(
            setting = MeasurementDevice.Settings.READFREQ,
            method  = lambda: self.bt_handler.fetch_value("GETCFGFREQ"),
            force_refresh = force_refresh,
        ))

    def set_measurement_frequency(self, value):
        # TODO: Check device and switch back to <
        if not (SpspSettings.__isnum__(value) and 0 <= int(value) < 64):
            raise self.ValidationError("Częstotliwość odczytu musi być liczbą w zakresie 1 do 63 [1/Hz]")
        out = self.__using_cache(
            setting = MeasurementDevice.Settings.READFREQ,
            method  = lambda val: self.bt_handler.fetch_value("SETCFGFREQ", val),
            set_value = value,
        )
        if out == 2**64:
            raise self.ValidationError("Błąd zapisu w pamięci urządzenia: niepoprawna wartość.")
        return out

    def get_sampling_size(self, force_refresh=False):
        return int(self.__using_cache(
            setting = MeasurementDevice.Settings.SAMPSIZE,
            method  = lambda: self.bt_handler.fetch_value("GETCFGSAMP"),
            force_refresh = force_refresh,
        ))

    def set_sampling_size(self, value):
        if not (SpspSettings.__isnum__(value) and 0 <= int(value) < 64):
            raise self.ValidationError("Wielkość próbkowania musi być liczbą w zakresie 0 do 63")
        return self.__using_cache(
            setting = MeasurementDevice.Settings.SAMPSIZE,
            method  = lambda val: self.bt_handler.send_cmd("SETCFGSAMP", val),
            set_value = value,
        )

    def get_bluetooth_name(self, force_refresh=False):
        return self.__using_cache(
            setting = MeasurementDevice.Settings.BTNAME,
            method  = lambda: self.bt_handler.fetch_value("GETBTNAME", data_type=BTHandler.CmdDataType.STRING),
            force_refresh = force_refresh,
        )

    def set_bluetooth_name(self, name):
        if not 0 < len(name) < 11:
            raise self.ValidationError("Nazwa urządzenia musi mieć od 1 do 10 znaków")

        for c in name:
            if BTHandler.char2spsp(c) == 63:
                raise self.ValidationError("Nazwa urządzenia może zawierać tylko znaki alfanumeryczne oraz następujące znaki specjalne: ~@#+-_:.,/\[]")

        return self.__using_cache(
            setting = MeasurementDevice.Settings.BTNAME,
            method  = lambda val: self.bt_handler.send_cmd("SETBTNAME", val, data_type=BTHandler.CmdDataType.STRING),
            set_value = name,
        )

    def get_display_timeout(self, force_refresh=False):
        return int(self.__using_cache(
            setting = MeasurementDevice.Settings.DISPTIME,
            method  = lambda: self.bt_handler.fetch_value("GETDISPOFF"),
            force_refresh = force_refresh,
        ))

    def set_display_timeout(self, value):
        if not (SpspSettings.__isnum__(value) and 0 <= int(value) < 64):
            raise self.ValidationError("Czas do wygaszenia wyświetlacza musi być liczbą w zakresie 0 do 63 [s]")

        return self.__using_cache(
            setting = MeasurementDevice.Settings.DISPTIME,
            method  = lambda val: self.bt_handler.send_cmd("SETDISPOFF", val),
            set_value = value,
        )

    def get_pressure_reference_value(self, force_refresh=False):
        return int(self.__using_cache(
            setting = MeasurementDevice.Settings.PRESSREF,
            method  = lambda: self.bt_handler.fetch_value("GETPRESSPT", data_type=BTHandler.CmdDataType.SIGNED),
            force_refresh = force_refresh,
        ))

    def set_pressure_reference_value(self, value):
        if not (SpspSettings.__isnum__(value) and -127 < int(value) < 128):
            raise self.ValidationError("Wartość referencyjna ciśnienia atm. musi być liczbą w zakresie -126 do 127 [hPa]")
        return self.__using_cache(
            setting = MeasurementDevice.Settings.PRESSREF,
            method  = lambda val: self.bt_handler.send_cmd("SETPRESSPT", val, data_type=BTHandler.CmdDataType.SIGNED),
            set_value = value,
        )

    def reset_to_factory_settings(self):
        self.reset_cache()
        return self.bt_handler.send_cmd("RESETCFG")

    @staticmethod
    def __isnum__(num):
        try:
            int(num)
            return True
        except ValueError:
            return False


class SpspAPI:
    logger = logging.getLogger('API.SpspAPI')
    bt_handler = None
    device_code = None
    device_addr = None
    device_bootup = None
    settings = SpspSettings()

    class MissingParam(BaseException):
        pass

    def __init__(self, device_code, addr=None):
        self.device_code = device_code

        if addr:
            self.device_addr = addr
        elif self.device_code:
            self.device_addr = MeasurementDevice.objects.get(code=self.device_code, setting=MeasurementDevice.Attributes.ADDR).value

        if not self.device_addr:
            raise self.MissingParam("Device address not provided and not found using the device_code")

        self.bt_handler = BTHandler(addr=self.device_addr, reset_uid_on_connect=True)
        self.settings.set_bt_handler(self.bt_handler)
        self.settings.set_device_code(self.device_code)

    def cleanup(self):
        self.bt_handler.cleanup()

    def get_time_of_bootup(self):
        if not self.device_bootup:
            self.logger.debug("Calculating device bootup time")
            before = timezone.now()
            stamp = int(self.bt_handler.fetch_value("GETTMSTAMP"))
            after = timezone.now()

            self.device_bootup = before + (after - before)
            self.device_bootup -= timezone.timedelta(seconds = stamp, microseconds = self.device_bootup.microsecond)

        return self.device_bootup

    def get_current_reading(self):
        reading = self.bt_handler.fetch_value("GETREADING", data_type=BTHandler.CmdDataType.RECORD)
        reading['datetime'] = timezone.datetime.fromtimestamp(self.get_time_of_bootup().timestamp() + reading['timestamp'])
        return reading

    def find_starting_offset(self, base_offset = 0):
        self.logger.debug("Searching for valid starting offset using base: " + str(base_offset))
        offset = base_offset
        rec_cnt = 0
        while offset < base_offset + 64:
            # try the next set of measurements
            rec_cnt = int(self.bt_handler.fetch_value("GETSTORED", {"offset": offset, "resolution": 1}, data_type=BTHandler.CmdDataType.STORED))
#             print("Got records: " + str(rec_cnt))
            if rec_cnt > 0:
                data = self.bt_handler.fetch_data(records = rec_cnt, warn = False, filter_invalid = False)
#                 print("with data: " + repr(data))
                for record in data['records']:
                    candidate_rcnt = int(self.bt_handler.fetch_value("GETSTORED", record['timestamp']))
#                     print("Checking candidate: " + str(record['timestamp']) + " with count: " + str(candidate_rcnt))
                    if candidate_rcnt:
                        candidate_data = self.bt_handler.fetch_data(records = candidate_rcnt, warn = False, filter_invalid = True)
#                         print("Got data: " + repr(candidate_data))
                        if len(candidate_data['records']) > 2:
                            # good enough
                            self.logger.debug("Found offset: " + str(record['timestamp']))
                            return record['timestamp']

            offset += 31

        self.logger.debug("Starting offset not found")
        return None

    def get_archived_reading(self, timeoffset = 0, fetch_all = False, warn = True):
        records = int(self.bt_handler.fetch_value("GETSTORED", timeoffset))
        if records > 0:
            data = self.bt_handler.fetch_data(records = records, filter_invalid = not fetch_all, warn = warn)
            if 'records' in data:
                return data['records']

        return []
