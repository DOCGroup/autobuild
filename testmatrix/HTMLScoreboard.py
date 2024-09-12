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
from pathlib import Path
from io import StringIO

from .matrix import Status


this_dir = Path(__file__).resolve().parent
indent = '  '


class Html:
    def __init__(self, indent_by=0):
        self.f = StringIO()
        self.indent_by = indent_by

    def print(self, *args, end='', **kw):
        print(*args, end=end, file=self.f, **kw)

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

    def __str__(self):
        return self.f.getvalue()


def tag(name, classes=None, attrs=None):
    t = '<' + name
    if attrs is None:
        attrs = {}
    if classes is None:
        classes = []
    if classes:
        attrs['class'] = ' '.join(classes)
    if attrs:
        t += ' ' + ' '.join([f'{k}="{v}"' for k, v in attrs.items()])
    return t + '>'


def full_tag(name, text, classes=None, attrs=None):
    if attrs is None:
        attrs = {}
    if classes is None:
        classes = []
    return tag(name, classes, attrs) + f'{text}</{name}>'


class HtmlTable:
    def __init__(self, name, cols, classes=[], attrs={}):
        self.name = name
        self.cols = cols
        self.header = (None, [], {})
        self.rows = [self.header]
        self.classes = classes
        self.attrs = attrs

    def row(self, cells, classes=[], attrs=None):
        if len(cells) != len(self.cols):
            raise ValueError(f'Got {len(cells)} cells, but we have {len(self.cols)} columns!')
        if attrs is None:
            attrs = {}
        self.rows.append(([c if type(c) is tuple else (c, [], {}) for c in cells], classes, attrs))

    def extra_header(self):
        self.rows.append(self.header)

    def done(self, html):
        html.println_push(tag('table', self.classes, self.attrs))
        for row, row_classes, row_attrs in self.rows:
            html.println_push(tag('tr', row_classes, row_attrs))
            html.print_indent()
            if row is None:  # Header
                for col in self.cols:
                    html.print(full_tag('th', col))
            else:  # Normal row
                for cell, cell_classes, cell_attrs in row:
                    html.print(full_tag('td', cell, cell_classes, cell_attrs))
            html.println('')
            html.pop_println('</tr>')
        html.pop_println('</table>')


class HTMLTestMatrix:
    def __init__(self, matrix, title):
        self.matrix = matrix
        self.title = title
        self.directory = matrix.builds.dir
        self.matrix_html_table = None
        self.matrix_header = None
        self.build_summary_html = None
        self.main_summary_html = None

        self.matrix_row = 0
        self.passed = 0
        self.failed = 0

        # TODO: Remove
        self.highlight_html = "onmouseover=\"this.style.backgroundColor='hotpink';\" onmouseout=\"this.style.backgroundColor='';\""

        # TODO: Remove JQuery
        self.html_start = """
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Strict//EN">
<html>
    <title>Scoreboard Matrix</title>
    <head>
    <style>
        @import "matrix.css";
    </style>
    <script src="http://code.jquery.com/jquery-1.11.0.min.js"></script>
    <script language="javaScript">
function showBuild(result, buildId) {
  var name = $(".txt:eq(" + (buildId - 1) + ")").html();
  alert("Build " + buildId + ":" + name + " " + result);
}

$(function() {
  var buildOffset = 3;
  $(".p,.f,.s").click(function() {
    var j = $(this);
    var buildId = j.index() - buildOffset;
    var result = "PASSED";
    if (j.hasClass("f")) {
      result = "FAILED";
    } else if (j.hasClass("s")) {
      result = "SKIPPED";
    }
    showBuild(result, buildId);
  });
});
    </script>
    </head>
    <body>
"""
        self.html_end = """</body></html>
"""

        self.key_html = """
<TABLE width="360">
    <colgroup>
    <col width="60">
    <col width="60">
    <col width="60">
    <col width="60">
    <col width="60">
    <col width="60">
    <tbody>
    <tr>
    <th class="head" colSpan="6">Key</th></tr>
    <tr>
    <th>Pass</th>
    <th>Fail</th>
    <th>Warn</th>
    <th>Skip</th>
    <th colspan="2">Compile Fail</th>
    <th></th>
    </tr>
    <tr class="odd">
    <td class="p">100%</td>
    <td class="f"><50%</td>
    <td class="w"><90%</td>
    <td class="s"></td>
    <td class="faillnk" colspan="2"></td>
  </tr>
  </TBODY>
</table>
"""

    def addTestData(self, name, results):
        if self.matrix_html_table is None:
            cols = ['# Pass', '# Fail', '# Skip', '% Pass']
            cols += [str(n + 1) for n in range(len(self.matrix.builds))]
            cols += ['Test Name']
            self.matrix_html_table = HtmlTable('Test Results', cols)

        tb = self.matrix_html_table

        self.matrix_row += 1

        # Repeat the header row every now and then
        if self.matrix_row % 20 == 0:
            tb.extra_header()

        row_classes = []

        # Alternate row color
        if self.matrix_row & 1:
            row_classes.append('odd')

        npass = results.stats.passed
        nfail = results.stats.failed
        nskip = results.stats.skipped

        # If any failed
        if nfail > 0:
            self.failed += 1
        elif npass > 0:
            self.passed += 1


        if nfail == 0:
            status_classes = []
        elif nfail == 1:
            status_classes = ['warn']
        else:
            status_classes = ['fail']

        row = [
            npass,
            (nfail, status_classes, {}),
            nskip,
            results.stats.perc_passed,
        ]
        for status in self.matrix.statuses_for_test(results):
            row.append(('', [status.name[0].lower()], {}))
        row.append((results.name, status_classes, {}))
        tb.row(row, row_classes)

    def getSummaryHTML(self, name, stats):
        # TODO: Use HtmlTable
        html = """
<table width="360">
    <col width="60"><col width="60"><col width="60"><col width="60"><col width="60"><col width="60">
    <tr>
        <th class="head" colspan="6">
"""
        html += name + """
Summary</th>
</tr>
<tr>
    <th># Total</th>
    <th># Pass</th>
    <th># Fail</th>
    <th># Skip</th>
    <th>% Pass</th>
    <th>% Fail</th>
</tr>
<tr class="odd">
"""

        html += '<td>%d</td>' % stats.total
        html += '<td>%d</td>' % stats.passed
        html += '<td>%d</td>' % stats.failed
        if stats.skipped == 0:
            html += '<td>-</td>'
        else:
            html += '<td>%d</td>' % stats.skipped
        html += f'<td>{stats.perc_passed}</td>'
        html += f'<td>{stats.perc_failed}</td>'
        html += '</tr>\n'
        html += '</table>\n'
        html += '<p>%d tests passed, ' % self.passed
        html += '%d failed</p>\n' % self.failed
        return html

    def writeBriefs(self):
        self.main_summary_html = self.getSummaryHTML("", self.matrix.all_stats)

    def writeBuildSummary(self, num, build):
        num += 1
        # TODO: Use HtmlTable
        if not self.build_summary_html:
            self.build_summary_html = """
<table>
    <col width="25">
    <col width="451">
    <col width="40">
    <col width="40">
    <col width="42">
    <col width="40">
    <col width="40">
    <tr>
        <th class="head" colspan="10">Build Summary</th>
    </tr>
    <tr>
        <th>#</th>
        <th>Name</th>
        <th>#</th>
        <th># Fail</th>
        <th>% Pass</th>
        <th># Skip</th>
        <th>Time (min)</th>
    </tr>
"""

        html = self.build_summary_html

        # now we have to write out the key to the build numbers
        # TODO: Rename and cleanup
        ace = 0.0
        acecls = None

        if build.stats.ran:
            ace = (build.stats.passed / build.stats.ran) * 100
            if ace < 50.0:
                acecls = "f"
            elif ace < 90.0:
                acecls = "w"

        # TODO?
        # if build.compile == FAIL:
        if False:
            html += '<tr class="faillnk" '
        elif num & 1:
            html += '<tr class="oddlnk" '
        else:
            html += '<tr class="lnk" '

        # TODO: Remove
        # Set up the ability for each row to act as a link (Easier to click)
        # Mozilla allows us to use the :hover tag in cvs with the tr, but this
        # doesn't work in IE. So we use onmouseover/out.
        fname = build.name + '_j.html'
        html += self.highlight_html
        html += " onmousedown=\"window.location ='%s';\">\n" % fname

        html += "<td>%d</td>" % num
        html += '<td class="txt">' + build.name + "</td>"
        html += "<td>%d</td>" % build.stats.total
        html += "<td>%d</td>" % build.stats.failed
        sperc = "%.1f" % ace
        if acecls:
            html += '<td class="' + acecls + '">'
        else:
            html += '<td>'
        html += sperc + "</td>"
        time = float(build.time) / 60.0
        timestr = "%.0f" % time
        html += "<td>%d</td>" % build.stats.skipped
        html += "<td>" + timestr + "</td>"

        self.build_summary_html = html

    def writeHTML(self):
        path = (self.directory / (self.title + ".html")).resolve()
        print(f'Writing html to {path}')

        if not self.build_summary_html:
            self.build_summary_html = ""
        if self.matrix_html_table is None:
            matrix_html = ''
        else:
            self.matrix_html_table.extra_header()
            matrix_html = Html()
            self.matrix_html_table.done(matrix_html)
        if not self.matrix_header:
            self.matrix_header = ""

        with path.open('w') as f:
            f.write(self.html_start)
            f.write(self.main_summary_html)
            f.write(self.key_html)
            f.write(self.build_summary_html)
            f.write("</table>")
            f.write(str(matrix_html))
            f.write("<br>Last updated at ")
            f.write(time.asctime(time.localtime()))
            f.write("<br>")
            f.write(self.html_end)

    def writeHTMLsummary(self):
        path = (self.directory / (self.title + "-summary.html")).resolve()
        print(f'Writing html summary to {path}')

        with path.open('w') as f:
            f.write(self.html_start)
            f.write(self.main_summary_html)
            f.write(self.html_end)


class HTMLPlatformTestTable:
    def __init__(self, title, dir):
        self.title = title
        self.directory = dir
        self.test_table_html = None
        self.rownum = 0

        self.html_start = """
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Strict//EN">
<html>
    <head>
        <style>
            @import "matrix.css";
        </style>
    </head>
    <body>
"""

        self.html_end = """
    </body>
</html>
"""

    def addData2(self, num, flag, time, name):
        # TODO: Use HtmlTable
        if not self.test_table_html:
            self.test_table_html = """
<table width="600">
    <col width="400"><col width="100"><col width="100">
    <tr>
        <th class="head" colspan="6">%s Details</th>
    </tr>
    <tr>
        <th>Name</th>
        <th>Pass/Fail</th>
        <th>Time</th>
    </tr>
""" % self.title
        html = self.test_table_html

        self.rownum += 1

        html += "<tr"
        if flag == PASS:
            result = "Pass"

        if flag == FAIL:
            html += ' class="faillnk"'
            result = "Fail"
        elif flag == SKIP:
            html += ' class="s"'
            result = "Skip"
        elif self.rownum & 1:
            html += ' class="odd"'
        html += ">"

        html += "<td>" + name + "</td>"
        html += "<td>" + result + "</td>"
        if time == 0.0:
            html += "<td>-</td>"
        else:
            timestr = "%.0f" % time
            if time > 300.0:
                html += '<td class="f">'
            elif time > 10.0:
                html += '<td class="w">'
            else:
                html += '<td>'
            html += timestr + "</td>"

        self.test_table_html = html

    def writeHTML(self):
        fname = self.directory + "/" + self.title + "_j.html"
        fname = os.path.normpath(fname)
        print("Writing html to '" + fname + "'")

        f = open(fname, "w", 1)
        try:
            f.write(self.html_start)
            if self.test_table_html:
                f.write(self.test_table_html)
                f.write("</table>")
            f.write(self.html_end)
        finally:
            f.close()


def write_html_matrix(matrix, prefix):
    html_tm = HTMLTestMatrix(matrix, prefix)
    for name, test in matrix.tests.items():
        html_tm.addTestData(name, test)

    html_tm.writeBriefs()
    for n, build in enumerate(matrix.builds):
        html_tm.writeBuildSummary(n, build)
    html_tm.writeHTML()
    html_tm.writeHTMLsummary()

    css = 'matrix.css'
    (matrix.builds.dir / css).write_text((this_dir / css).read_text())
