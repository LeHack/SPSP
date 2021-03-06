# -*- coding: utf-8 -*-
# Generated by Django 1.10.3 on 2017-01-14 18:55
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('webui', '0001_initial'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='station',
            name='url',
        ),
        migrations.AddField(
            model_name='parser',
            name='url',
            field=models.URLField(default='http://null.com', verbose_name='adres zasobu'),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='station',
            name='code',
            field=models.CharField(default='NONE', max_length=100, verbose_name='identyfikator'),
            preserve_default=False,
        ),
    ]
