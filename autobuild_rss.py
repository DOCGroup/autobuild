#!/usr/bin/python

from optparse import OptionParser
import sys, string
import xml.sax
import xml.sax.handler
from xml.dom.minidom import getDOMImplementation
from datetime import datetime

rfc822 = "%a, %d %b %Y %H:%M:%S GMT"

def parse_args ():
    parser = OptionParser ()

    parser.add_option ("-i", dest="input", default="",
                       help="Scoreboard configuration file to generate reports")
    parser.add_option ("-o", dest="output", default="",
                       help="Filename to output report to")
    parser.add_option ("-n", dest="number", default=10,
                       help="Number of recent builds to include")
    parser.add_option ("--uri-regex", dest="uri_regex", default="", nargs=2,
                       help="Regular expression used to transform URIs.  Must be two strings, separated by a space, ie: --uri-regex search replace")
    parser.add_option ("-a", dest="name", default="DOC Group Scoreboard"
                       help="Feed name")
    return parser.parse_args ()

(opts, args) = parse_args ()

class ScoreboardHandler (xml.sax.handler.ContentHandler):
    def __init__ (self):
        self.pos = list ()
        self.state = dict ()
        self.builds = list ()
        return

    def startElement (self, name, attrs):
        self.pos.append (name)
        
        if name == "build":
            self.state["name"] = ""
            self.state["url"] = ""
            self.state["sponsor"] = ""
            
        return

    def characters (self, content):
        name = self.pos[-1]

        self.state[name] = content

    def endElement (self, name):

        if self.pos.pop () != name:
            print "ERROR: endElement called for a state we shouldn't be in: " + name
            return

        if name == "build":
            self.builds.append ((self.state["name"], self.state["url"], self.state["sponsor"]))

### Helper methond to append a text node onto a DOM tree.
def appendTextNode (doc, parent, name, value) :
    ele = doc.createElement (name)
    ele.appendChild (doc.createTextNode (str (value)))
    parent.appendChild (ele)
                     
class RSSItem :
    def __init__ (self):
        self.title = ""
        self.link = ""
        self.description = ""
        self.pubDate = datetime.utcnow ()
        self.guid = ""

    def to_xml (self, parent, doc):
        item = doc.createElement ("item")

        appendTextNode (doc, item, "title", self.title)
        appendTextNode (doc, item, "link", self.link)
        appendTextNode (doc, item, "description", self.description)
        appendTextNode (doc, item, "pubDate", self.pubDate.strftime (rfc822))
        appendTextNode (doc, item, "guid", self.guid)

        parent.appendChild (item)
        return
    
class RSSChannel :
    def __init__ (self):
        self.title = ""
        self.link = ""
        self.desc = ""
        self.language = "en-us"
        self.pubDate = datetime.utcnow ()
        self.lastBuildDate = self.pubDate
        self.generator = "DOC Group Scoreboard RSS System"
        self.managingEditor = "bczar@dre.vanderbilt.edu"
        self.webMaster = "bczar@dre.vanderbilt.edu"
        self.items = list ()

    def add_item (self, item):
        self.items.append (item)
        
    def to_xml (self, parent, doc):
        channel = doc.createElement ("channel")
        appendTextNode (doc, channel, "title", self.title)
        appendTextNode (doc, channel, "link", self.link)
        appendTextNode (doc, channel, "description", self.desc)
        appendTextNode (doc, channel, "language", self.language)
        appendTextNode (doc, channel, "pubDate",  self.pubDate.strftime (rfc822))
        appendTextNode (doc, channel, "lastBuildDate", self.lastBuildDate.strftime (rfc822))
        appendTextNode (doc, channel, "generator", self.generator)
        appendTextNode (doc, channel, "managingEditor", self.managingEditor)
        appendTextNode (doc, channel, "webMaster", self.webMaster)

        parent.appendChild (channel)
        for item in self.items:
            item.to_xml (channel, doc)

class RSS :
    def __init__ (self):
        self.channels = list ()

    def add_channel (self, channel):
        self.channels.append (channel)

    def to_xml (self, outFile):
        impl = xml.dom.minidom.getDOMImplementation ()
        rssdoc = impl.createDocument (None, "rss", None)

        top = rssdoc.documentElement
        top.setAttribute ("version", "2.0")

        for channel in self.channels:
            channel.to_xml (top, rssdoc)

        outfile = file (opts.output, 'w')
        outfile.write (rssdoc.toprettyxml ("  "))
        outfile.close

        # Clean up
        rssdoc.unlink ()
        
def parse (filename):
    handler = ScoreboardHandler ()
    parser = xml.sax.make_parser ()
    parser.setContentHandler (handler)

    infile = file (filename, 'r')
    parser.parse (infile)
    infile.close ()

    return handler

def fetch_latest (builds):
    import re
    from urllib import urlopen
    
    latest_builds = list ()

    valid_latest = re.compile ("\d\d\d\d_\d\d")
    
    for build in builds:
        uri = build[1]
        
        if opts.uri_regex != "":
            uri = re.sub (opts.uri_regex[0],
                          opts.uri_regex[1],
                          uri)

        latest = urlopen (uri + "/latest.txt")

        #Get the contents, and make sure it represents a valid latest file
        string = latest.read ()
        if valid_latest.match (string) != None:
            latest_builds.append ((build[0],build[1],string))
        else:
            print "ERROR: " + build[0] + " returned an invalid latest file!"
        latest.close ()

    return latest_builds

def main ():
#    (opts, args) = parse_args ()

    if (opts.input == "") or (opts.output == ""):
        print "Error: Must supply both -i and -o arguments."
        return -1

    handler = parse (opts.input)
    latest = fetch_latest (handler.builds)

    ## Sort in decending order of completion
    latest.sort (cmp=lambda x, y: cmp(x[2], y[2]), reverse=True)

    # Prune off all but the request number of entries...
    latest = latest[0:int (opts.number)]

    chan = RSSChannel ()
    chan.title = opts.name
    chan.desc = "Build results"
    chan.link = "http://www.dre.vanderbilt.edu/scoreboard"
    for build in latest:
        item = RSSItem ()
        item.title = build[0]
        item.link = build[1] + "/index.html"
        item.guid = build[1] + "/" + build[2][0:16] + "_Totals.html"
        item.description = build[2]
        item.pubDate = datetime (int (build[2][0:4]), # Year
                                 int (build[2][5:7]),
                                 int (build[2][8:10]),
                                 int (build[2][11:13]),
                                 int (build[2][14:16]))
        chan.add_item (item)

    rss = RSS ()
    rss.add_channel (chan)

    rss.to_xml (opts.output)
        
    return 0

if __name__ == "__main__":
    main ()
    
