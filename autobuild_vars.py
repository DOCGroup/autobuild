
from optparse import OptionParser
import sys, string
import xml.sax
import xml.sax.handler

def parse_args ():
    parser = OptionParser ()

    parser.add_option ("-u", action="store_true", dest="unix", default=False,
                       help="Use Unix environment characteristics")
    parser.add_option ("-w", action="store_true", dest="windows", default=False,
                       help="Use Windows environment characteristics")

    return parser.parse_args ()

class AutobuildHandler (xml.sax.handler.ContentHandler):
    def __init__ (self):
        self.env_map = dict ()
        # Constructor
        return

    def startElement (self, name, attrs):
        if name == "environment":
            self.env_map [attrs.get ("name")] = attrs.get ("value")

def main ():
    (opts, args) = parse_args ()

    if len(args) != 1:
        print "Must pass exactly one argument to this script."
        return
    
    # Create the parser
    handler = AutobuildHandler ()
    parser = xml.sax.make_parser ()
    parser.setContentHandler (handler)

    # Parse
    inFile = file (args[0], 'r')
    parser.parse (inFile)
    inFile.close ()

    # Set up characteristics
    set_expr = ""
    sep_expr = ""
    var_pre_expr = ""
    var_post_expr = ""
    
    if opts.unix:
        set_expr = "export "
        sep_expr = ":"
        var_pre_expr = "$"
    elif opts.windows:
        set_expr = "set "
        sep_expr = ";"
        var_pre_expr = "%"
        var_post_expr = "%"
    else:
        print "You must specify either unix or windows!"
        exit
        
    for variable, value in handler.env_map.iteritems ():
        command =  set_expr + variable + "=" + value

        if variable.find ("PATH") != -1:
            command += sep_expr + var_pre_expr + variable + var_post_expr

        print command



if __name__ == "__main__":
    main ()
