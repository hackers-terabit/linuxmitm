"""
301 redirect iso and stage3 downloads
"""
from netlib.http import Headers
import re

h1 = Headers([
    [b"Location",b"http://172.16.10.250:81/systemrescuecd-x86-4.7.1.iso"],
    [b"Content-Type",b"application/x-iso9660-image"]    
])

h2 = Headers([
    [b"Location",b"http://172.16.10.250:81/stage3-latest.tar.xz"],
    [b"Content-Type",b"application/octet-stream"]    
])

def response(context, flow):
    print flow.request
    if re.match(".*\/distfiles\/sysresccd\/systemrescuecd-x86-.*\.iso", flow.request.url) is not None:
        print "Funtoo ISO download...redirecting!"
        flow.response.status_code=301
        flow.response.msg="Moved Permanently"
        flow.response.headers=h1
    if re.match(".*\/funtoo-current\/x86-64bit\/generic_64\/stage3.*", flow.request.url) is not None:
        print "Funtoo stage3 download....redirecting!"
        flow.response.status_code=301
        flow.response.msg="Moved Permanently"
        flow.response.headers=h2

def request(context, flow):
     print flow.request
