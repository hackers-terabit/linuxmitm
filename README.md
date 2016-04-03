# Backdooring Linux installation media: Survey of GNU/Linux and BSD family operating system's installation process security

# Problem description:

   Servers and workstations with Gnu/Linux or bsd family unix operating systems have a well designed,tested and thought out security architecture.
   Administrators of these systems spend hours if not days of their lives securing and hardening their operating system installs.

   However a system cannot be secured if the installation of that system to begin with, has been compromised.
   
   This proof-of-concept project attempts to simplify and automate the process of performing a man-in-the-middle
   attack and weaken the installation process of various operating system distributions.
   
   The threat model is a man in the middle (MITM) attacker who has already compromisedany number of devices between 
   the victim's computer (or virtual-machine) and the server hosting the operating system's installation media.
   
   Security between distribution publisher and installation media mirror-server is not covered here.

   In this particular simulation,the compromised computer is a linux machine that forwards and routes network traffic for the victim's computer.

   Using the proof of concept script (and/or) the well known open source tools used by the script, the attacker will be able to insert a revrese shell
   backdoor that he/she can later use to insert a more complex and targeted payload(s) to further compromise the victim's machine.
   
   The backdoor itself is extremely simple, it's only purpose is to show a backdoor is possible. 
   
   This project aims to show not only technical shortcomings but policy shortcomings as well. 
   
   We've followed installtion instructions posted on the website of the said distributions as accurately as possible in our testing.
   
   On some distributions the man-in-the-middle attack was simple to achieve, on others difficult and on a few it was not possilbe at all.
   
# Proposed solutions
### HTTPS 

   Open source distribution maintainers should be using HTTPS (or any other connection with third party domain or server validation) for their installation media downloads.

   At the time of this writing most if not all major Linux distributions host installation media over HTTP and FTP connections.

   Their reasoning is this:
   users can use cryptographic hash verification or PGP public key verification to validate the integrity and authenticity of the installation
   media.

   Their approach has a few problems
   + It requires users to take the extra and often [relatively] complex set of steps to validate the installation media
   + It assumes users are aware of the security concerns and dangers at hand
   + The operating system distributions sometimes host the PGP fingerprint along with cryptographic hash files over HTTP OR FTP.
       if the attacker can modify the download media,so can he/she modify these signatures
   + most current gpg installations use the HKP protocol to "refresh" and fetch the public key corresponding with the fingerprint,
       the HKP protocol in turn uses plain-text HTTP over a non-standard port for this action - the attacker who already has access
       to network traffic can simply serve the user a PGP fingerprint as well as corresponding public key over HKP to validate
       the compromised installation media(this for the above scenario where the attacker controls the PGP fingerprint as well).
   + As previous research (e.g.: https://evil32.com) has shown, usage of the "short" version of GPG fingerprint is vulnerable to a birthday attack (collisions)
   
   If distribution maintainers refuse to use HTTPS even as a non-default option for installation media download,then they must maintain hash,pgp fingerprints and torrent files
   over HTTPS.
   
   Furthermore, PGP and hash verification instructions must be documented and maintained well. 
   
   The verification instructions must be written so that *anyone with minimal technical expertise* can follow along.
   Such instructions most also be posted plainly as a mandatory requirement of the installation procedure on the same page a user initiates the download process.
   
   
#### The many imperfections of TLS

   TLS and the CA system are far from perfect. however simply using HTTPS will force the attacker to compromise the CA's or the user's computer
   (to inject a malicious CA  certificate) before he/she can attempt the type of attack described above.

   HTTPS/TLS is not mutually exclusive with GPG verification or cryptographic hash verification.
   Using TLS does not protect against a compromised server or a malicious mirror-server.

   Performance over HTTPS  compared to HTTP is not significant enough to overlook the security beneifits of the protocol.
   if performance is a problem there is nothing preventing distribution maintainers from offering HTTP side-by-side with HTTPS.

   It is not all that difficult to imagine (as the PoC will show) for a linux firewall or router to be compromised (does not need to be linux obviously).
   however there is a significant challenge and difficulty for a majority of malicious actors on the internet to compromise a Certificate Authority.
   
   Absolute security is neither purused or expected as a result of using TLS or HTTPS. the only thing expected is a significant improvement in integrity
   and authenticity validation  of installation media.
   
   What we advocate here is "best-effort" security on the part of distribution maintainers. 
# Torrent download security

This subject has yet to be explored in detail outside of theoretical discussion.

# Brief summary of installation process security for popular distributions

   The table below summarizes the latest survey we've made of the distributions in question (top 10 on distrowatch.com + funtoo/gentoo just because!  )
 
|    Distribution     |   HTTPS Download   |   Hash checksum   |   PGP   |  GPG/Hash over HTTPS   |   Download page has PGP verification instructions   |  Short/Long PGP fingerprint   |   Torrent   | Torrent file over HTTPS   |PoC working/tested | 
| :-------         |          ----: | :---:         |:-------   |   :-------       |   :-------                                  |  :-------   | :-------   |     :-------        |       :------- |       :------- 
| Funtoo Linux | NO |  sha256    | NO | NO | NO | N/A| NO | NO | Yes
| Ubuntu        | NO | sha256 md5 | Yes| NO | NO | Short | Yes| NO| NO
| Mint         | NO | md5        | Yes| NO | NO | ?? | Yes| NO | NO
| Debian       | NO | md5,sha    | Yes| BOTH*|NO| ?? |Yes | NO | NO
| Mageia       | NO | md5,sha256 | Yes | NO|NO| ?? |Yes|NO | NO
| Fedora       | NO | sha256     | Yes | NO | Yes | ?? |Yes| Yes | NO
| openSUSE     | NO | sha256     | Yes | Only GPG Fingerprint| NO | ?? | Yes | NO | NO
| Arch Linux   | NO | sha1,md5 | Yes | Yes | NO | ?? | Yes | Yes | NO
| Centos      | NO | sha,md5 | Yes | NO | NO | ?? | Yes | NO | NO
| PCLinuxOS   |NO | md5      | NO | NO | NO | N/A | Yes | NO | NO
| Slackware   |NO | md5      | Yes| NO | NO | ?? | Yes | NO | NO
| Gentoo      |NO | sha      | Yes | Yes|NO| ?? | NO | NO | NO
| FreeBSD     |NO| md5,sha256| Yes |BOTH*| NO | ?? |NO| NO | NO

# PoC usage:

Please bear in mind, the PoC is still under continued development.

Usage: `poc.sh <Victim's IP>  <Command and control IP>`

# Contribute

Fork this project and contribute!

# Collaborate

Find us on IRC on freenode.net in ##hackers

