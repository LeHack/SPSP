# -*- coding: utf-8 -*-
# Generated by Django 1.10.3 on 2018-06-05 06:54
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('webui', '0005_parameter_unit'),
    ]

    operations = [
        migrations.AddField(
            model_name='parameter',
            name='label',
            field=models.CharField(default='A', max_length=100, verbose_name='etykieta UI'),
            preserve_default=False,
        ),
    ]
