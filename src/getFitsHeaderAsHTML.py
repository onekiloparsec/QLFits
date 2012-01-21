#!/usr/bin/env python
# encoding: utf-8
#
#  getFitsHeaderAsHTML.py
#  QLFits
#
#  Created by Cédric Foellmi on 14/10/08.
#
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

import sys
import os
import re
import time
import string

__version__        = "2.4.0"
__abort_time_limit = 3.0
__num_images       = int(sys.argv[2])


header_start = """
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN"><html><head><title>QLFits Generated HTML</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<style type="text/css">
	#fits-header       { top:0px; left:0px; height:%spx; width:100%%; overflow-y:scroll; display:block; border:0; }
	#fits-full-header  { top:0px; left:0px; background:#EEEEEE; height:100%%; width:100%%; position:absolute; border:0; }
	#fits-images-frame { top:0px; left:0px; height:100%%; width:100%%; border:0px; overflow-y:auto; overflow:hidden; }
	#fits-header-core  { background:#EEEEEE; font-family:"Monaco"; font-size:%spx; }
	#title             { top:3px; right:10px; position:absolute; font-family:"Helvetica Neue"; font-size:10px; }
	#ESO-links		   { display:%s; font-size:13px; } #ESO-links a { color:blue; }
	#quick-summary     { display:%s; } #tabs { font-size:12px; }
</style>
<link type="text/css" href="css/%s/jquery-ui-1.7.2.custom.css" rel="stylesheet"/>
<script type="text/javascript" src="js/jquery-1.3.2.min.js"></script>
<script type="text/javascript" src="js/jquery-ui-1.7.2.custom.min.js"></script>	
<script type="text/javascript">		
	$(document).ready(function() { 
		$("#tabs").tabs();
		$("#fits-header").resizable({ handles:'se, s, sw', minWidth:793, minHeight:10, containment:'parent' }); });
</script>
</head><body style="border:0px; margin:0; padding:0; overflow-x:hidden;">
"""%(sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6], sys.argv[7])
  
if __num_images == 0:
	header_start += """<div id="fits-full-header">"""
else:
	header_start += """<div id="fits-header" class="ui-widget-content">"""

header_start += """<div id="title">Powered by QLFits (v%s) [<a href="http://www.softtenebraslux.com">Soft Tenebras Lux</a>]</div>"""%(__version__)
header_start += """<center><h3 class="ui-state-highlight">%s (Primary Header)</h3></center>"""%(os.path.basename(sys.argv[1]))
header_finish = "</div>"

if __num_images == 0:
	images = ""
elif __num_images == 1:
	images = """
	<div id="fits-images-frame" class="ui-widget-content">
		<img src="file:///tmp/QLFits_%s_ext1.tiff" width=100%%>
	</div>"""%(os.environ['USER'])
else:
	images = """<div id="tabs" class="ui-widget-content"><ul>\n"""
	for i in range(__num_images):
		images += """<li><a href="#tabs-%i">Extension %i</a></li>\n"""%(i+1, i+1)
	images += "</ul>"
	for i in range(__num_images):
		images += """<div id="tabs-%i"><img src='file:///tmp/QLFits_%s_ext%i.tiff' width=100%%></div>"""%(i+1, os.environ['USER'], i+1)
	images += "</div>"

abort_message = """<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN"><HTML><HEAD><TITLE> QLFits Generated HTML</TITLE></HEAD>
	<BODY BGCOLOR="#EEEEEE"><center><h4>QLFits takes too long to read your FITS file.<br>Stopping after %.4f seconds.</h4>
	If you encounter too frequent aborts because of a too small time limit,<br>please contact
	the <a href="mailto:postmaster@softtenebraslux.com">Soft Tenebras Lux</a> developper (C&eacute;dric Foellmi).
	<br><small>(This is QLFits version %s)</small><P><br><hr size=1 width=90%%></center>
"""%(__abort_time_limit, __version__)

footer = "</body></html>"


# MUST be instrument names as they appear at the beginning of the archive filename.
LASILLA_INS_LIST = ['EMMI', 'FEROS', 'SOFI', 'SUSI2', 'CES', 'HARPS', 'WFI', 'SUSI', 'EFOSC', 'EFOSC2']
PARANAL_INS_LIST = ['ISAAC', 'CRIRES', 'AMBER', 'FORS1', 'FORS2', 'VISIR', 'FLAMES', 'UVES', 'MIDI', 'VIMOS', \
					'NACO', 'SINFO', 'HAWKI', 'VISTA', 'GIRAF']

ESO_FILE_URL = "http://archive.eso.org/wdb/wdb/eso/eso_archive_main/query?dp_id=%s&format=SexaHour&tab_stat_plot=on&aladin_colour=aladin_instrument"
ESO_PROG_URL = "http://archive.eso.org/wdb/wdb/eso/sched_rep_arc/query?progid=%s"
ESO_SEEING_URL = "http://archive.eso.org/asm/ambient-server?site=%s&mjd=%s"

def isESOLine(line):
	return line.startswith("HIERARCH ESO")

def isCommentLine(line):
	if '=' in line and (line.index('=') == 8 or line.index('=') == 29):
		return False
	return True

def hasBracketValue(line):
	if line.count("'") == 2:
		return True
	return False

def parseValue(line):
	subline = line.split("=")[1]
	if hasBracketValue(subline):
		start = subline.lfind("'")
		stop  = subline.rfind("'")
		return subline[start-1:stop+1]
	if '/' in subline[22:]:
		stopIndex = subline.index('/')
		return subline[:stopIndex-1]
	return subline

def parseComment(line):
	if hasBracketValue(line):
		stopValue = line.rfind("'")
		startComment = line[stopValue:].index('/')
		return line[stopValue:][startComment:]	
	subline = line.split("=")[1]
	if '/' in subline[22:]:
		startComment = subline.index('/')
		return subline[startComment+1:]
	return ""

class Line:
	def __init__(self, key="", value="", comment=""):
		self.key     = {'value':key, 'color':"darkblue", 'size':8, 'replace':True, 'end':"=&nbsp;"}
		self.value   = {'value':value, 'color':"green", 'size':22, 'replace':True, 'end':"/&nbsp;"}
		self.comment = {'value':comment, 'color':"#333333", 'size':50, 'replace':False, 'end':""}
		self.components = []

	def tohtml(self):
		html = "&nbsp;"
		for item in [self.key, self.value, self.comment]:
			if len(item['value']) > 0:
				s = item['value'].ljust(item['size'])
				if item['replace']: s = s.replace(" ", "&nbsp;")
				else: s = s.strip()
				html += "<font color=%s>%s</font>%s"%(item['color'], s, item['end'])
		return html+"<br>"


class ESOLine(Line):
	def __init__(self, key="", value="", comment=""):
		Line.__init__(self, key=key, value=value, comment=comment)
		self.key['size'] = 31
		self.value['size'] = 12
		self.comment['size'] = 37

		# The idea is to have all colors below being variations of red.
		if self.key['value'].startswith("HIERARCH ESO DET"):
			self.key['color'] = "darkred"
		elif self.key['value'].startswith("HIERARCH ESO INS"):
			self.key['color'] = "purple"
		elif self.key['value'].startswith("HIERARCH ESO OBS"):
			self.key['color'] = "orange"
		elif self.key['value'].startswith("HIERARCH ESO TEL"):
			self.key['color'] = "darkpurple"


class HeaderLines:
	def __init__(self):
		self._ls = []
		self.mjd = ["", "Modified Julian Date", " "]
		self.arcfile = ["", "Archive Filename", " "]
		self.instrument = ["", "Instrument", " "]
		self.progid = ["", "Program ID", " "]
		self.telescope = ["", "Telescope Name", " "]
		self.objectname = ["", "Object Name", " "]
		self.observatoryname = ["", "Observatory", " "]
		self.observatory = ["", "", " "]
		self.utc = ["", "Universal Time", " "]
		self.lst = ["", "Local Sidereal Time", " "]
		self.ra = ["", "Right Ascension", " "]
		self.dec = ["", "Declination", " "]
		self.exptime = ["", "Exposure Time", "(sec)"]
		self.observer = ["", "Observer", " "]
		self.detector = ["", "Detector", " "]

	def append(self, line):
		if isCommentLine(line):
			self._ls.append(Line(key="", value="", comment=line))
		
		elif isESOLine(line):
			self._ls.append(ESOLine(**self.__parseLine(line)))

		else:
			self._ls.append(Line(**self.__parseLine(line)))
		
	def __parseLine(self, line):
		k = line.split('=')[0]
		v = parseValue(line)
		c = parseComment(line)
		self.__checkSummaryInfos(k, v, c)
		return {'key':k, 'value':v, 'comment':c}

	def __checkSummaryInfos(self, k, v, c):
		if k.startswith("MJD-OBS"):
			self.mjd[0] = v
		elif k.startswith("ARCFILE"):		
			self.arcfile[0] = v
			# Better to use ARC[HIVE]FILE to get instrument rather than INSTRUM key that can contain version numbers.
			self.instrument[0] = v.split(".")[0]
			if self.instrument[0] in LASILLA_INS_LIST:
				self.observatory = ['lasilla', 'La Silla Observatory']
				self.observatoryname[0] = 'La Silla Observatory'
			elif self.instrument[0] in PARANAL_INS_LIST:
				self.observatory = ['paranal', 'Very Large Telescope']
				self.observatoryname[0] = 'Paranal Observatory'			
		elif k.startswith("HIERARCH ESO OBS PROG ID"):		
			self.progid[0] = v
		elif k.startswith("TELESCOP"):		
			self.telescope[0] = v
		elif k.startswith("OBJECT") or k.startswith("HIERARCH ESO OBS TARG NAME") or k.startswith("TARGNAME"):
			self.objectname[0] = v
		elif k.startswith("RA "):
			self.ra[0] = v
			if ':' not in v and c.strip() != '':
				self.ra[2] = "("+c.split()[0]+")"
		elif k.startswith("DEC"):
			self.dec[0] = v
			if ':' not in v and c.strip() != '':
				self.dec[2] = "("+c.split()[0]+")"
		elif k.startswith("UTC") or k.startswith("UT "):
			self.utc[0] = v
			try:
				self.utc[2] = "("+c.split()[0]+")"
			except IndexError:
				pass
		elif k.startswith("LST"):
			self.lst[0] = v
			try:
				self.lst[2] = "("+c.split()[0]+")"
			except IndexError:
				pass
		elif k.startswith("EXPTIME"):
			self.exptime[0] = v
		elif k.startswith("OBSERVER"):
			self.observer[0] = v
		elif k.startswith("DETECTOR"):
			self.detector[0] = v
		elif k.startswith("INSTRUM") and self.arcfile[0] == "":		
			self.instrument[0] = v

	def quickSummary(self):
		html = """<table width=100%% class="ui-widget-content" style="font-size:11px; border:0; font-family:'Lucida Grande', sans-serif;">"""
		for item in [[self.observatoryname, self.ra], \
					 [self.telescope, self.dec], \
					 [self.instrument, self.progid], \
					 [self.detector, self.mjd], \
					 [self.objectname, self.utc], \
					 [self.exptime, self.lst]]:
#					 self.arcfile]:
			html += "<tr><td width=80px>&nbsp;%s</td><td width=200px>= <b>%s %s</b></td>"%\
						(item[0][1].ljust(21).replace(" ", "&nbsp;"), item[0][0] or "?", item[0][2] or "?")
			html += "<td width=80px>&nbsp;%s</td><td width=200px>= <b>%s %s</b></td></tr>"%\
						(item[1][1].ljust(21).replace(" ", "&nbsp;"), item[1][0] or "?", item[1][2] or "?")
		html += "</table>"
		if len(html) > 0:
			html = """<div id="quick-summary" class="ui-widget-content" style="border:0;"><center>Quick Summary</center><br>""" + \
					html + "<center><br></center></div>"
		return html
		
	def ESOLinks(self):
		html = ""
		if self.progid[0] or (self.mjd[0] and self.arcfile[0]):
			html = "<center><hr size=1 width=90%>&nbsp;External Links to <a href='www.eso.org'>ESO</a> archive:<br>"
		if self.arcfile[0]:
			s = ESO_FILE_URL%(self.arcfile[0].replace('.fits', ''))
			html += "&nbsp;&nbsp;<a href='%s'>File Description</a>"%(s)
		if self.progid[0]:
			s = ESO_PROG_URL%(self.progid[0])
			html += "&nbsp;&nbsp;<a href='%s'>Abstract of Proposal</a>"%(s)
		if self.mjd[0] and self.arcfile[0]:
			s = ESO_SEEING_URL%(self.observatory[0], self.mjd[0])
			html += "&nbsp;&nbsp;<a href='%s'>Ambient Conditions (seeing)</a>"%(s)
			html += "<br>Observatory (guessed from instrument): %s"%(self.observatory[1])
		if self.progid[0] or (self.mjd[0] and self.arcfile[0]):
			html += "</font><br></center>"
		if len(html) > 0:
			html = """<div id="ESO-links" class="ui-widget-content" style="border:0;">""" + \
					html + "<br></div>"
		return html
		
	def tohtml(self):
		html = """<div id="fits-header-core"><br>"""
		for line in self._ls:
			html += line.tohtml()
		html += "</div>"
		return self.quickSummary() + self.ESOLinks() + html
			
fits = open(sys.argv[1], 'r')
headerLines = HeaderLines()        
rawdata = fits.read(80) # 80 characters blocks
start = time.time()
while not re.search("^checksum", rawdata, re.I) and not re.search("^end", rawdata, re.I):
	if len(rawdata) > 1:
		headerLines.append(rawdata.replace("'","")) 
	if time.time() > start + __abort_time_limit:
		sys.stdout.write(abort_message + headerLines.tohtml() + header_finish + footer)
		sys.exit(0)
  	rawdata = fits.read(80)

fits.close()
sys.stdout.write(header_start + headerLines.tohtml() + header_finish + images + footer)
sys.exit(0)

