import json
import enum
from pathlib import Path


class Status(enum.Enum):
    Passed = (True, 0, '✅')
    Failed = (True, 1, '❌')
    Skipped = (False, 2, '__')

    @property
    def is_a_run(self):
        return self.value[0]

    @property
    def index(self):
        return self.value[1]

    @property
    def emoji(self):
        return self.value[2]


class TestStats:
    statuses = {s.name.lower(): s for s in Status}

    def __init__(self):
        self.total = 0
        self.ran = 0
        self._counts = [0] * len(Status)

    def __getitem__(self, status):
        return self._counts[status.index]

    def __iadd__(self, status):
        self._counts[status.index] += 1
        self.total += 1
        if status.is_a_run:
            self.ran += 1
        return self

    def __bool__(self):
        return bool(self.ran)

    def perc(self, status):
        d = self.ran if status.is_a_run else self.total
        return format(self[status] / d, '.2%')

    def __str__(self):
        s = f'{self.ran} ran'
        for name, status in self.statuses.items():
            count = self[status]
            if count:
                name = status.name.lower()
                perc = self.perc(status)
                s += f', {count} {name} ({perc})'
        return s


for name, status in TestStats.statuses.items():
    # Make a copy for each status, otherwise the lambdas get the same Status
    # object.
    setattr(TestStats, name, property(lambda self, s=Status(status): self[s]))
    setattr(TestStats, f'perc_{name}', property(lambda self, s=Status(status): self.perc(s)))


class TestRun:
    def __init__(self, name: str, result: int, time: int, misc=None):
        if misc is None:
            misc = {}
        self.name = name
        extra_name = misc.get('extra_name', None)
        if extra_name:
            self.name += '-' + misc['extra_name']
        self.result = result
        self.time = time
        self.misc = misc

    def __bool__(self):
        return self.result == 0

    @property
    def status(self):
        return Status.Passed if self else Status.Failed

    def __str__(self):
        return f'{self.name}: time={self.time} result={self.result}'


class Build:
    def __init__(self, name, builds_dir, misc=None):
        if misc is None:
            misc = {}
        self.name = name
        self.dir = builds_dir / name
        self.misc = misc
        self.stats = TestStats()

        build_json = self.dir / (misc['basename'] + '.build.json')
        with build_json.open('r') as f:
            data = json.load(f)

        self.tests = {}
        self.time = 0
        for t in data['tests']:
            test_run = TestRun(t['name'], int(t['result']), int(t['time']), t)
            if test_run.name in self.tests:
                raise ValueError(f'Multiple {repr(test_run.name)} in {self.name}!')
            self.tests[test_run.name] = test_run
            self.time += test_run.time

    def __iter__(self):
        return iter(self.tests.values())

    def __getitem__(self, key):
        return self.tests[key]

    def __contains__(self, key):
        return key in self.tests


class Builds:
    def __init__(self, builds_dir):
        self.dir = builds_dir

        builds_json = builds_dir / 'builds.json'
        with builds_json.open('r') as f:
            data = json.load(f)

        self.builds = {}
        for b in data['builds']:
            name = b['name']
            self.builds[name] = Build(name, builds_dir, b)

    def __len__(self):
        return len(self.builds)

    def __iter__(self):
        return iter(self.builds.values())


class Test:
    def __init__(self, name):
        self.name = name
        self.runs = {}
        self.stats = TestStats()

    def add_run(self, build: Build, test: TestRun):
        self.runs[build.name] = (build, test)

    def status_for_build(self, build_name):
        return self.runs[build_name][1].status if build_name in self.runs else Status.Skipped

    def __len__(self):
        return len(self.runs)


class Matrix:
    def __init__(self, builds: Builds):
        self.builds = builds
        self.tests = {}
        self.all_stats = TestStats()

        # Collect all the tests
        for build in builds:
            for test_run in build:
                n = test_run.name
                if n in self.tests:
                    test = self.tests[n]
                else:
                    test = Test(n)
                    self.tests[n] = test
                test.add_run(build, test_run)

        # Colect stats
        for name, test in self.tests.items():
            for build in builds:
                status = test.status_for_build(build.name)
                test.stats += status
                build.stats += status
                self.all_stats += status

    def statuses_for_test(self, test):
        for build in self.builds:
            yield test.status_for_build(build.name)

    def dump(self):
        for name, test in self.tests.items():
            for status in self.statuses_for_test(test):
                print(status.emoji, end='')
            print(' ', test.stats, name)

        print()
        for n, build in enumerate(self.builds):
            print(f'[{n}] {build.name}: {build.stats}')

        print()
        print('All:', self.all_stats)
