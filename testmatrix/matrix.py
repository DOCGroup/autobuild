import sys
import os
import json
import enum
from datetime import timedelta
from pathlib import Path


use_ansi = os.name != 'nt' and sys.stdout.isatty()


class Status(enum.Enum):
    Passed = (True, 0, '\033[0;42m+\033[0m', '+')
    Failed = (True, 1, '\033[0;41mX\033[0m', 'X')
    Skipped = (False, 2, '.', '.')

    @property
    def is_a_run(self):
        return self.value[0]

    @property
    def index(self):
        return self.value[1]

    @property
    def text(self):
        return self.value[2 if use_ansi else 3]


def timedelta_str(td):
    # str(td) would work, but it returns a string that's longer than it
    # needs to be.
    days, rem_hours = divmod(round(td.total_seconds()), 24 * 60 * 60)
    hours, rem_mins = divmod(rem_hours, 60 * 60)
    mins, secs = divmod(rem_mins, 60)

    s = ''

    if days:
        s += f'{days} day'
        if td.days > 1:
            s += 's'
        if rem_hours:
            s += ' '

    if hours:
       s += f'{hours}:'

    if mins:
        if hours:
            s += f'{mins:02}:'
        else:
            s = f'{mins}:'

    if hours or mins:
        s += f'{secs:02}'
    else:
        s += f'{secs} s'

    return s


class TestStats:
    statuses = {s.name.lower(): s for s in Status}

    def __init__(self):
        self.ran = 0
        self._counts = [0] * len(Status)
        self.time = None
        self.max_time = timedelta()
        self.min_time = timedelta.max

    def __getitem__(self, status):
        return self._counts[status.index]

    def add(self, status: Status, time=None):
        self._counts[status.index] += 1
        if status.is_a_run:
            self.ran += 1
            if time is not None:
                if self.time is None:
                    self.time = timedelta()
                self.time += time
                self.max_time = max(self.max_time, time)
                self.min_time = max(self.min_time, time)

    def time_str(self):
        return timedelta_str(self.time)

    def avg_time(self):
        return timedelta(seconds=(self.time.total_seconds() / self.ran))

    def avg_time_str(self):
        return timedelta_str(self.avg_time())

    def __bool__(self):
        return bool(self.ran)

    def set_skipped(self, n):
        self._counts[Status.Skipped.index] = n

    def total(self):
        return sum(self._counts)

    def perc(self, status):
        d = self.ran if status.is_a_run else self.total()
        return (self[status] / d) * 100 if d else 0

    def perc_str(self, status):
        return format(self.perc(status) / 100, '.2%')

    def __str__(self):
        s = f'{self.ran} ran'
        for name, status in self.statuses.items():
            count = self[status]
            if count:
                name = status.name.lower()
                perc = self.perc_str(status)
                s += f', {count} {name} ({perc})'
        if self.time is not None:
            s += ', avg ' + self.avg_time_str()
        return s


for name, status in TestStats.statuses.items():
    # Make a copy for each status, otherwise the lambdas get the same Status
    # object.
    setattr(TestStats, name, property(lambda self, s=Status(status): self[s]))
    setattr(TestStats, f'perc_{name}', property(lambda self, s=Status(status): self.perc(s)))
    setattr(TestStats, f'perc_{name}_str', property(lambda self, s=Status(status): self.perc_str(s)))


class TestRun:
    def __init__(self, name: str, result: int, time: timedelta, misc=None):
        if misc is None:
            misc = {}
        self.name = name
        extra_name = misc.get('extra_name', None)
        if extra_name:
            self.name += ' ' + misc['extra_name']
        self.subsection = misc['subsection']
        self.result = result
        assert type(time) is timedelta
        self.time = time
        self.misc = misc

    def __bool__(self):
        return self.result == 0

    @property
    def status(self):
        return Status.Passed if self else Status.Failed

    def time_str(self):
        return timedelta_str(self.time)

    def __str__(self):
        return f'{self.name}: time={self.time_str()} result={self.result}'


class Build:
    def __init__(self, name, builds_dir, misc=None):
        if misc is None:
            misc = {}
        self.name = name
        self.dir = builds_dir / name
        self.misc = misc
        self.stats = TestStats()
        self.basename = misc['basename']
        self.props = misc.get('props', {})

        build_json = self.dir / (self.basename + '.build.json')
        with build_json.open('r') as f:
            data = json.load(f)

        self.tests = {}
        for t in data['tests']:
            test_run = TestRun(t['name'], int(t['result']), timedelta(seconds=int(t['time'])), t)
            self.stats.add(test_run.status, test_run.time)
            if test_run.name in self.tests:
                raise ValueError(f'Multiple {repr(test_run.name)} in {self.name}!')
            self.tests[test_run.name] = test_run

    def __iter__(self):
        return iter(self.tests.values())

    def __getitem__(self, key):
        return self.tests[key]

    def __contains__(self, key):
        return key in self.tests


class Test:
    def __init__(self, name, build_test_run_pairs, build_count):
        self.name = name
        self.runs = {}
        self.stats = TestStats()

        for build, test_run in build_test_run_pairs:
            self.runs[build.name] = (build, test_run)
            self.stats.add(test_run.status, test_run.time)

        self.stats.set_skipped(build_count - len(build_test_run_pairs))

    def run_and_status_for_build(self, build_name):
        if build_name in self.runs:
            run = self.runs[build_name][1]
            return (run, run.status)
        return (None, Status.Skipped)

    def status_for_build(self, build_name):
        return self.run_and_status_for_build(build_name)[1]

    def __len__(self):
        return len(self.runs)


class Matrix:
    def __init__(self, builds_dir: Path):
        self.dir = builds_dir
        self.all_stats = TestStats()

        builds_json = builds_dir / 'builds.json'
        with builds_json.open('r') as f:
            data = json.load(f)

        self.props = data['props']

        # Collect all the builds
        self.builds = {}
        for b in data['builds']:
            name = b['name']
            build = Build(name, builds_dir, b)
            self.builds[name] = build

        # Collect all the tests
        all_tests = {}
        for build in self.builds.values():
            for test_run in build:
                n = test_run.name
                if n in all_tests:
                    all_tests[n].append((build, test_run))
                else:
                    all_tests[n] = [(build, test_run)]

        # We now know both the total number of builds and tests.
        self.tests = {}
        for test_name, build_test_run_pairs in all_tests.items():
            self.tests[test_name] = Test(test_name, build_test_run_pairs, len(self.builds))
        for build in self.builds.values():
            build.stats.set_skipped(len(self.tests) - build.stats.ran)

        # Sort tests by % percent passed ascending, then name (case insensitive)
        self.tests = {n: t for n, t in sorted(self.tests.items(),
            key=lambda nt: (nt[1].stats.perc_passed, nt[0].lower()))}

        # Collect all stats
        for name, test in self.tests.items():
            for build in self.builds.values():
                run, status = test.run_and_status_for_build(build.name)
                self.all_stats.add(status, None if run is None else run.time)

    def statuses_for_test(self, test):
        for build in self.builds.values():
            yield test.status_for_build(build.name)

    def dump(self):
        for name, test in self.tests.items():
            for status in self.statuses_for_test(test):
                print(status.text, end='')
            print(' ', test.stats, name)

        print()
        for n, build in enumerate(self.builds.values()):
            print(f'[{n}] {build.name}: {build.stats}')

        print()
        print('All:', self.all_stats)
