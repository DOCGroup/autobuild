#!/usr/bin/python

# ******************************************************************
#      Author: Heather Drury
#              Justin Michel
#              Chris Cleeland
#        Date: 7/12/2004
#         $Id$
# ******************************************************************

import sys, string, fileinput, re, math, os, time

from utils import *

class HTMLTestMatrix2:
	def __init__ (self, title, directory):
		self.title = title
		self.directory = directory
		self.matrix_html = None 
		self.matrix_header = None
		self.build_summary_html = None
		self.main_summary_html = None
		self.tao_summary_html = None
		self.ace_summary_html = None

		self.matrix_row = 0

		self.highlight_html = "onmouseover=\"this.style.backgroundColor='hotpink';\" onmouseout=\"this.style.backgroundColor='';\""
		
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
		self.html_start += time.strftime('%X %x %Z')
		print "TIME IS:", "TIME IS:", time.strftime('%X %x %Z')

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
	<th	class="head" colSpan="6">Key</th></tr>
	<tr>
	<th>Pass</th>
	<th>Fail</th>
	<th>Warn</th>
	<th>Skip</th>
	<th	colspan="2">Compile	Fail</th>
	<th></th>
	</tr>
	<tr class="odd">
	<td	class="p">100%</td>
	<td	class="f"><50%</td>
	<td	class="w"><90%</td>
	<td	class="s"></td>
	<td	class="faillnk"	colspan="2"></td>
  </tr>
  </TBODY>
</table>
"""

	def getTestDataHeader(self, name, results, builds):
		"""Adds another header row to the test results table."""
		html = """
<tr>
	<th># Pass</th>
	<th># Fail</th>
	<th># Skip</th>
	<th>% Pass</th>
"""
		for n in range (0, len(results)):
			number = str(n+1)
			## Insert spaces between two digit numbers, so that they will wrap
			if len(number) == 2:
				number = number[0]+ ' ' + number[1]
			if builds:
				bldname = builds[n].name
				html += '<th  class="colhead" title="' + bldname + '">' + number + '</th>'
			else:
				html += '<th>' + number + '</th>'
			
		## Add the final <th> and end the header row
		return html + '<th>Test Name</th></tr>\n'
		

	def addTestData (self, name, results, linkfile, builds=None):

		if not self.matrix_html:
			width = 160 + (10 * len(results)) + 500
			## Mozilla ignores the table-layout css attribute unless you specify <table width="...
			html = '<table width="%d" class="matrix">' % width
			html += """<col width="40"><col width="40"><col width="40"><col width="40">"""
			## Add <col> specifiers for each build
			for n in range (0, len(results)):
				html += '<col width="10">'
			## Add the final <col>
			html += '<col width="500">\n'

			## Add a caption
			html += '<tr><th class="head" colspan="%d">Test Results</td></tr>\n' % (len(results) + 5)

			html += self.getTestDataHeader(name, results, builds)
			
			self.matrix_html = html

		if not self.matrix_header:
			self.matrix_header = self.getTestDataHeader(name, results, builds)

		self.matrix_row += 1

		html = self.matrix_html

		# Repeat the header row every now and then
		if self.matrix_row % 20 == 0:
			html += self.matrix_header
		
		npass = results.count (PASS)
		nfail = results.count (FAIL)
		nskip = results.count (SKIP)
		perc = ComputePercentage (npass, npass + nfail)
		sperc = "%.0f" % perc

		if self.matrix_row & 1:
			html += '<tr class="odd"'
		else:
			html += '<tr class="even"'
		html += self.highlight_html + ">"
			
		html += "<td>%d</td>" % npass
		html += "<td>%d</td>" % nfail
		html += "<td>%d</td>" % nskip
		if perc < 50.0:
			html += '<td class="f">' + sperc + "</td>"
		elif perc < 90.0:
			html += '<td class="w">' + sperc + "</td>"
		else:
			html += '<td>' + sperc + "</td>"
			
		## now write out the <td>s for test results
		for res in results:
			if res == PASS:
				html += '<td class="p"></td>'
			elif res == FAIL:
				html += '<td class="f"></td>'
			else:
				html += '<td class="s"></td>'
			
		## now write out the name of the test
		##fname = str(linkfile) + '.html'
		html += '<td>' + name + '</td>'
		
		self.matrix_html = html + "</tr>\n"		

	def getSummaryHTML (self, name, npass, nfail, nskip):
		total = npass + nfail
		pperc = ComputePercentage (npass, total)
		fperc = ComputePercentage (nfail, total)
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
		
		html += '<td>%d</td>' % total
		html += '<td>%d</td>' % npass
		html += '<td>%d</td>' % nfail
		if nskip == -1:
			html += '<td>-</td>'
		else:
			html += '<td>%d</td>' % nskip
		html += '<td>%.1f</td>' % pperc
		html += '<td>%.1f</td>' % fperc
		html += '</tr>\n'
		return html

	def writeBriefs (self, npass, nfail, nskip):
		self.main_summary_html = self.getSummaryHTML("", npass, nfail, nskip)

	def writeSummary (self, ACEpass, ACEtotal, ACEperc, TAOpass, TAOtotal, TAOperc):
		self.ace_summary_html = self.getSummaryHTML("ACE ", ACEpass, (ACEtotal - ACEpass), -1)
		self.tao_summary_html = self.getSummaryHTML("TAO ", TAOpass, (TAOtotal - TAOpass), -1)

	def writeBuildSummary (self, num, build):
		num += 1 
		if not self.build_summary_html:
			self.build_summary_html = """
<table width="800">
	<col width="25">
	<col width="451">
	<col width="40">
	<col width="40">
	<col width="42">
	<col width="40">
	<col width="40">
	<col width="42">
	<col width="40">
	<col width="40">
	<tr>
		<th class="head" colspan="10">Build Summary</th>
	</tr>
	<tr>
		<th colspan="2"></th>
		<th colspan="3">ACE</th>
		<th colspan="3">TAO</th>
		<th colspan="2"></th>
	</tr>
	<tr>
		<th>#</th>
		<th>Name</th>
		<th>#</th>
		<th># Fail</th>
		<th>% Pass</th>
		<th>#</th>
		<th># Fail</th>
		<th>% Pass</th>
		<th># Skip</th>
		<th>Time (min)</th>
	</tr>
"""

		html = self.build_summary_html 
		
		# now we have to write out the key to the build numbers
		ace = tao = 0.0
		acecls = None
		taocls = None
		
		if build.ACEtotal > 0:
			npass = build.ACEtotal - build.ACEfail
			ace = ComputePercentage (npass, build.ACEtotal)
			if ace < 50.0:
				acecls = "f"
			elif ace < 90.0:
				acecls = "w"
				
		if build.TAOtotal > 0:
			npass = build.TAOtotal - build.TAOfail
			tao = ComputePercentage (npass, build.TAOtotal)
			if tao < 50.0:
				taocls = "f"
			elif tao < 90.0:
				taocls = "w"

		if build.compile == FAIL:
			html += '<tr class="faillnk" '
		elif num & 1:
			html += '<tr class="oddlnk" '
		else:
			html += '<tr class="lnk" '

		## Set up the ability for each row to act as a link (Easier to click)
		## Mozilla allows us to use the :hover tag in cvs with the tr, but this 
		## doesn't work in IE. So we use onmouseover/out.
		fname = build.name + '_j.html'
		html += self.highlight_html
		html += "onmousedown=\"window.location ='%s';\">\n" % fname

		html += "<td>%d</td>" % num
		html += '<td class="txt">' + build.name + "</td>"
		html += "<td>%d</td>" % build.ACEtotal
		html += "<td>%d</td>" % build.ACEfail
		sperc = "%.1f" % ace
		if acecls:
			html += '<td class="' + acecls + '">'
		else:
			html += '<td>'
		html += sperc + "</td>"
		html += "<td>%d</td>" % build.TAOtotal
		html += "<td>%d</td>" % build.TAOfail
		sperc = "%.1f" % tao
		if taocls:
			html += '<td class="' + taocls + '">'
		else:
			html += '<td>'
		html += sperc + "</td>"
		time = float(build.timeTotal) / 60.0 
		timestr = "%.0f" % time
		html += "<td>%d</td>" % build.nskip
		html += "<td>" + timestr + "</td>"
		
		self.build_summary_html = html

	def writeHTML (self):
		fname = self.directory + "/" + self.title + ".html"
		fname = os.path.normpath(fname)
		print "Writing html to '" + fname + "'"
	
		f = open(fname, "w", 1)
		try:
			f.write(self.html_start)
			f.write(self.main_summary_html)
			f.write("</table>")
			f.write(self.ace_summary_html)
			f.write("</table>")
			f.write(self.tao_summary_html)
			f.write("</table>")
			f.write(self.key_html)
			f.write(self.build_summary_html)
			f.write("</table>")
			f.write(self.matrix_html)
                        f.write(self.matrix_header)
			f.write("</table>")
			f.write(self.html_end)
		finally:
			f.close()
	
        def writeHTMLsummary (self):
                fname = self.directory + "/" + self.title + "-summary.html"
                fname = os.path.normpath(fname)
                print "Writing html summary to '" + fname + "'"
        
                f = open(fname, "w", 1)
                try:
                        f.write(self.html_start)
                        f.write(self.main_summary_html)
                        f.write("</table>")
                        f.write(self.ace_summary_html)
                        f.write("</table>")
                        f.write(self.tao_summary_html)
                        f.write("</table>")
                        f.write(self.html_end)
                finally:
                        f.close()


class HTMLPlatformTestTable:
	def __init__ (self, title, dir):
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

	def addData2 (self, num, flag, time, name):
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

	def writeHTML (self):
		fname = self.directory + "/" + self.title + "_j.html"
		fname = os.path.normpath(fname)
		print "Writing html to '" + fname + "'"
	
		f = open(fname, "w", 1)
		try:
			f.write(self.html_start)
			if self.test_table_html:
				f.write(self.test_table_html)
				f.write("</table>")
			f.write(self.html_end)
		finally:
			f.close()

class HTMLTestFile:
	def __init__ (self, title, dir):
		self.title = title
		self.directory = dir

	def addData2 (self, flag, name):
		pass

	def writeHTML (self):
		print "HTMLTestFile not supported."

