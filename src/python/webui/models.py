from django.db import models
from django.utils import timezone


class Area(models.Model):
    name = models.CharField('nazwa', max_length=100)
    city = models.CharField('miasto', max_length=100)

    class Meta:
        verbose_name = "obszar"
        verbose_name_plural = "obszary"

    def __str__(self):
        return self.name


class Parser(models.Model):
    name = models.CharField('nazwa', max_length=100)
    url  = models.URLField('adres zasobu', null=True, blank=True)

    def __str__(self):
        return self.name


class Station(models.Model):
    name    = models.CharField('nazwa', max_length=100)
    street  = models.CharField('ulica', max_length=100)
    added   = models.DateField('data dodania', default=timezone.now)
    area    = models.ForeignKey(Area, related_name='stations', on_delete=models.CASCADE)
    parser  = models.ForeignKey(Parser, related_name='stations', on_delete=models.CASCADE)
    code    = models.CharField('identyfikator', max_length=100)

    class Meta:
        verbose_name = "stacja"
        verbose_name_plural = "stacje"

    def __str__(self):
        return "%s [%s]" % (self.name, self.code)


class Parameter(models.Model):
    name        = models.CharField('nazwa', max_length=100)
    label       = models.CharField('etykieta UI', max_length=100)
    description = models.CharField('opis', max_length=1024, null=True, blank=True)
    norm        = models.FloatField('norma godzinowa (µg)', null=True, blank=True)
    unit        = models.CharField('jednostka', max_length=20)

    class Meta:
        verbose_name = "parametr"
        verbose_name_plural = "parametry"

    def __str__(self):
        return self.name


class Measurement(models.Model):
    date    = models.DateTimeField('czas pomiaru')
    value   = models.FloatField('wartość')
    type    = models.ForeignKey(Parameter, related_name='measurements', on_delete=models.CASCADE)
    station = models.ForeignKey(Station, related_name='measurements', on_delete=models.CASCADE)

    class Meta:
        verbose_name = "pomiar"
        verbose_name_plural = "pomiary"

    def __str__(self):
        return "%s [%s]" % (self.type, self.date.strftime('%Y-%m-%d %H:%M:%S'))


class Measurement15mAggr(models.Model):
    date    = models.DateTimeField('czas pomiaru')
    date_s  = models.DateField('data pomiaru')
    value   = models.FloatField('wartość')
    type    = models.ForeignKey(Parameter, on_delete=models.DO_NOTHING)
    station = models.ForeignKey(Station, on_delete=models.DO_NOTHING)

    class Meta:
        indexes = [
            models.Index(fields=['date_s', 'type']),
        ]
        verbose_name = "pomiar uśredniony"
        verbose_name_plural = "pomiary uśrednione"

    def __str__(self):
        return "%s [%s]" % (self.type, self.date.strftime('%Y-%m-%d %H:%M'))
