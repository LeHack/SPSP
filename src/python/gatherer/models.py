from django.db import models
from django.utils import timezone


class Gatherer(models.Model):
    WORKING = 'WORKING'
    READY   = 'READY'
    STATUS = (
        (WORKING, 'Przetwarzanie'),
        (READY,   'Gotowe'),
    )
    UI   = 'UI'
    CRON = 'CRON'
    RUNBY = (
        (UI,   'Interfejs'),
        (CRON, 'Harmonogram'),
    )
    status     = models.CharField('Stan', max_length=10, choices=STATUS, default=READY)
    run_by     = models.CharField('Uruchomiony przez', max_length=10, choices=RUNBY, default=CRON)
    start_time = models.DateTimeField('Czas uruchomienia', default=timezone.now)

    def __str__(self):
        return "%s @ %s [%s]" % (self.get_run_by_display(), self.start_time.strftime("%Y-%m-%d %H:%M:%S"), self.get_status_display())
