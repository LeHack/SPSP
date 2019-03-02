from enum import Enum
from django.db import models
from django.utils import timezone


class MeasurementDevice(models.Model):
    class Settings(Enum):
        PM10NORM = 1
        READFREQ = 2
        SAMPSIZE = 3
        DISPTIME = 4
        PRESSREF = 5
        BTNAME   = 6

    class Attributes(Enum):
        ADDR     = 11
        LOCATION = 12

    code        = models.CharField('Identyfikator urządzenia', max_length=50)
    setting     = models.CharField(max_length=30, choices=[(s, s) for s in filter(lambda x: not str(x).startswith('__'), sorted(dir(Settings) + dir(Attributes))) ])
    value       = models.CharField(max_length=50, default=None)
    modified    = models.DateTimeField(auto_now=True)

    def __str__(self):
        return "%s > %s = %s [modified: %s]" % (self.code, self.param, self.value, timezone.datetime.strftime(self.modified, "%Y-%m-%d %H:%M:%S"))

    def save(self):
        if self.value is None:
            self.value = self.get_default(self.setting)
        super(MeasurementDevice, self).save()

    defaults = {
        Settings.PM10NORM: 50,
        Settings.READFREQ: 60,
        Settings.SAMPSIZE: 10,
        Settings.DISPTIME: 10,
        Settings.PRESSREF: -35,
        Settings.BTNAME: "SPSP-001",
    }
    def get_default(self, setting):
        return self.defaults[setting] if setting in self.defaults else None

    @staticmethod
    def clear_settings(code):
        MeasurementDevice.objects.filter(code = code, setting__startswith = "Setting").delete()
