import datetime, json, multiprocessing, subprocess

from abc import ABC, abstractmethod

from .models import Gatherer
from smogtrac import settings
from webui.models import Station


class AbstractWorker(ABC, multiprocessing.Process):
    json = ""

    def run(self):
        data = self.gather()
        if data:
            self.process(data)
        return

    @abstractmethod
    def gather(self):
        pass

    @abstractmethod
    def process(self):
        pass


def import_from(module, name):
    module = __import__(module, fromlist=[name])
    return getattr(module, name)


class Manager:
    ''' Runs parsers and handles errors '''
    run_by   = None
    stations = None
    pm_type  = None
    day      = None

    def __init__(self, pm_type, day = datetime.date.today(), run_by = None, stations = None):
        self.pm_type = pm_type
        self.day     = day
        if stations:
            self.stations = stations
        else:
            self.stations = Station.objects.all()

        if run_by:
            self.run_by = getattr(Gatherer, run_by)

    def run(self):
        parsers = []

        # create a WIP status in the DB
        state = Gatherer(status = Gatherer.WORKING)
        if self.run_by:
            state.run_by = self.run_by
        state.save()

        # load a parser for every station and run them
        for station in self.stations:
            module = import_from('gatherer.parsers.%s' % (station.parser.name), station.code)
            parser = module(self.pm_type, self.day, station)
            parser.start()
            parsers.append(parser)

        for parser in parsers:
            parser.join()

        # update state, to indicate we're done
        state.status = Gatherer.READY
        state.save()

    def fireAndForget(self):
        params = [
            settings.BASE_DIR + '/scripts/manager.py',
            '--pm_type', self.pm_type
        ]

        if self.run_by:
            params.append('--run_by')
            params.append(self.run_by)

        if self.stations:
            params.append('--stations')
            params.append(json.dumps([s.code for s in self.stations]))

        # we run ourselves from an external script, which will be detached from our caller
        subprocess.Popen(params)

    @staticmethod
    def isReady():
        result = None
        if Gatherer.objects.count() > 0:
            result = (Gatherer.objects.latest('start_time').status == Gatherer.READY)
        return result
