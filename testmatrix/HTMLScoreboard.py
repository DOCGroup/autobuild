# ******************************************************************
#      Author: Heather Drury
#              Justin Michel
#              Chris Cleeland
#        Date: 7/12/2004
# ******************************************************************

import sys
import re
import os
import time
import json
import html
from pathlib import Path
from io import StringIO
from contextlib import contextmanager

from .matrix import Status, Build, Matrix


this_dir = Path(__file__).resolve().parent
indent = '    '


def relative_to(a, b):
    return os.path.relpath(a.resolve(), b.resolve().parent)


class HtmlPage:
    def __init__(self, path: Path, title: str, js: Path = None, css: Path = None):
        self.path = path
        self.title = title
        self.js = js
        self.css = css
        self.file = None
        self.indent_by = 0

    def print(self, *args, end='', **kw):
        print(*args, end=end, file=self.file, **kw)

    def print_indent(self):
        self.print(indent * self.indent_by)

    def println(self, *args, **kw):
        self.print_indent()
        self.print(*args, end='\n', **kw)

    def println_push(self, *args, **kw):
        self.println(*args, **kw)
        self.indent_by += 1

    def pop_println(self, *args, **kw):
        assert self.indent_by > 0
        self.indent_by -= 1
        self.println(*args, **kw)

    @contextmanager
    def block(self, tag):
        tag = Tag(tag)
        self.println_push(tag.begin())
        try:
            yield None
        finally:
            self.pop_println(tag.end())

    def __enter__(self):
        if self.path is not None:
            self.file = self.path.open('w')
        self.println('<!DOCTYPE html>')
        self.println('<html>')
        with self.block('head'):
            self.println(Tag('title', self.title))
            if self.css:
                self.println(Tag('link', rel='stylesheet', href=self.css))
            if self.js:
                self.println(Tag('script', '', src=self.js))
        self.println('<body>')
        return self

    def __exit__(self, exc_type, exc_value, exc_traceback):
        if exc_traceback is None:
            self.println('</body>')
            self.println('</html>')
        if self.file is not None:
            self.file.close()


class Tag:
    def __init__(self, n=None, t=None, c=[], **attrs):
        if type(n) is Tag:
            self.name = n.name
            self.text = n.text
            self._classes = n._classes
            self._attrs = n._attrs
        else:
            self.name = n
            self.text = t
            self._classes = c
            self._attrs = attrs

    def with_name(self, name):
        t = Tag(self)
        if self.name is None:
            t.name = name
        return t

    def with_text(self, text):
        t = Tag(self)
        if self.text is None:
            t.text = text
        return t

    def begin(self):
        rv = '<' + self.name
        attrs = self._attrs.copy()
        if self._classes:
            attrs['class'] = ' '.join(self._classes)
        for k, v in attrs.items():
            v = html.escape(str(v))
            rv += f' {k}="{html.escape(v)}"'
        return rv + '>'

    def end(self):
        return f'</{self.name}>'

    def __str__(self):
        rv = self.begin()
        if self.text is not None:
            text = str(self.text) if type(self.text) is Tag else html.escape(str(self.text))
            rv += text + self.end()
        return rv


class HtmlTable:
    def __init__(self, title, cols, page=None, tag=Tag(), row_tag=Tag()):
        self.title = title
        self.cols = cols
        self.page = page
        self.tag = tag
        self.title_row = [Tag('th', self.title, ['head'], colspan=len(cols))]
        self.header = [Tag('th', c) for c in cols]
        self.rows = [self.title_row, self.header]
        self.row_tag = Tag(row_tag).with_name('tr')

    def row(self, cells, default_tag=Tag()):
        if len(cells) != len(self.cols):
            raise ValueError(f'Got {len(cells)} cells, but we have {len(self.cols)} columns!')
        tags = []
        for cell in cells:
            tag = cell if type(cell) is Tag else default_tag.with_text(cell)
            tags.append(tag.with_name('td'))
        self.rows.append(tags)

    def extra_header(self):
        self.rows.append(self.header)

    def done(self, page):
        with page.block(self.tag.with_name('table')):
            for cells in self.rows:
                with page.block(self.row_tag):
                    page.print_indent()
                    for cell in cells:
                        page.print(cell)
                    page.print('\n')

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, exc_traceback):
        if exc_traceback is None:
            self.done(self.page)

    @classmethod
    def write_simple(cls, page, title, cols, rows):
        with cls(title, cols, page) as table:
            for row in rows:
                table.row(row)


def get_build_details_path(build, basename):
    build.dir.mkdir(parents=True, exist_ok=True)
    return build.dir / f'{basename}-build-details.html'


def write_build_summary_table(page, matrix, basename):
    cols = ['#', 'Name', '# Ran', '# Failed', '% Passed', '# Skipped', 'Total Time']
    with HtmlTable('Build Summary', cols, page=page) as tb:
        for n, build in enumerate(matrix.builds.values()):
            perc_classes = []
            s = build.stats
            if s.ran:
                perc = s.perc_passed
                if perc < 50.0:
                    perc_classes.append('f')
                elif perc < 90.0:
                    perc_classes.append('w')
            link = Tag('a', t=build.name,
                href=relative_to(get_build_details_path(build, basename), page.path))
            tb.row([n, Tag(t=link, c='txt'), s.ran, s.failed,
                Tag(t=s.perc_passed_str, c=perc_classes), s.skipped, s.time_str()])


def write_test_matrix_table(page, matrix):
    cols = ['# Pass', '# Fail', '# Skip', '% Pass', 'Avg Time']
    cols += [Tag('div', '', ['empty']) for n in range(len(matrix.builds))]
    cols += ['Test Name']

    with HtmlTable('Test Results', cols, page,
            tag=Tag(c=['test_results']), row_tag=Tag(c=['test_row'])) as tb:
        matrix_row = 0
        for name, results in matrix.tests.items():
            matrix_row += 1

            # Repeat the header row every now and then
            if matrix_row % 40 == 0:
                tb.extra_header()

            npass = results.stats.passed
            nfail = results.stats.failed
            nskip = results.stats.skipped
            if nfail == 0:
                status_classes = []
            elif nfail == 1:
                status_classes = ['w']
            else:
                status_classes = ['f']

            row = [
                npass,
                Tag(t=nfail, c=status_classes),
                nskip,
                results.stats.perc_passed_str,
                results.stats.avg_time_str(),
            ]
            for build_n, build in enumerate(matrix.builds.values()):
                run, status = results.run_and_status_for_build(build.name)
                attrs = {'build': build_n}
                if run is not None:
                    attrs['test'] = run.subsection
                row.append(Tag(t='', c=[status.name[0].lower()], **attrs))
            row.append(Tag(t=results.name, c=status_classes + ['test_name']))
            tb.row(row)

        tb.extra_header()


def write_matrix_html(matrix: Matrix, title: str, basename: str, get_css, get_js):
    path = matrix.dir / f'{basename}-matrix.html'
    with HtmlPage(path, title, get_css(path), get_js(path)) as page:
        page.println(Tag('h1', title))

        s = matrix.all_stats
        HtmlTable.write_simple(page, 'Summary',
            ['# Ran', '# Pass', '# Fail', '# Skip', '% Pass', '% Fail', 'Time'],
            [[s.ran, s.passed, s.failed, s.skipped,
                s.perc_passed_str, s.perc_failed_str, s.time_str()]])

        HtmlTable.write_simple(page, 'Key',
            ['Pass', 'Fail', 'Warn', 'Skip'],
            [[Tag(t='100% Passed', c=['p']), Tag(t='<50% Passed', c=['f']),
                Tag(t='<90% Passed', c=['w']), '']])

        write_build_summary_table(page, matrix, basename)

        write_test_matrix_table(page, matrix)

        page.println("<br>Last updated at ")
        page.println(time.asctime(time.localtime()))


def write_build_details_html(build: Build, build_n, basename: str, get_css, get_js):
    path = get_build_details_path(build, basename)
    with HtmlPage(path, f'{build.name} Details', get_css(path), get_js(path)) as p:
        table = HtmlTable(p.title, ['', 'Time', 'Name'], tag=Tag(c=['test_results']))
        for test in build:
            table.row([
                Tag(c=[test.status.name[0].lower()], t='', test=test.subsection, build=build_n,),
                test.time_str(),
                Tag(t=test.name, c=['test_name']),
            ])
        table.done(p)


def copy_assets(matrix, basename):
    out_path = matrix.dir

    matrix_js = 'matrix.js'
    js_out = out_path / f'{basename}-{matrix_js}'
    js_out.write_text('\n'.join(['var {} = {};'.format(k, json.dumps(v)) for k, v in dict(
        build_info=[{
            'name': b.name,
            'basename' : b.basename,
            'props': b.props,
        } for b in matrix.builds.values()],
        props=matrix.props,
    ).items()]) + '\n\n' + (this_dir / matrix_js).read_text())

    matrix_css = 'matrix.css'
    css_out = out_path / f'{basename}-{matrix_css}'
    css_out.write_text((this_dir / matrix_css).read_text())
    return [(lambda html_path, p=p: relative_to(p, html_path)) for p in [js_out, css_out]]


def write_html_files(matrix, title, basename):
    get_js, get_css = copy_assets(matrix, basename)

    write_matrix_html(matrix, title, basename, get_js, get_css)

    for n, build in enumerate(matrix.builds.values()):
        write_build_details_html(build, n, basename, get_js, get_css)
