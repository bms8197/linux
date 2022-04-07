#!/usr/bin/env python

# show_vpn_users.py
#
# Author: Bogdan Stoica <bogdan at 898 dot ro>
# 202-04-04 Version 0.1
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions
#    and the following disclaimer.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# The script should run locally on a linux server running OpenVPN server with management enabled
#
# To enable the management interface for OpenVPN just add:
# management 127.0.0.1 29523 to /etc/openvpn/server.conf
# restart the openvpn service
#

import telnetlib
import time
import sys
import os
import re
import argparse

parser = argparse.ArgumentParser(description='Check VPN connected users')
parser.add_argument("-u", "--users [USERS]", dest="users", help="Only check these users (eg. user1, user2)", default='', required=False)
args = parser.parse_args()

#if len(sys.argv) == 1:
#    parser.print_help()
#    sys.exit(0)

if args.users:
    args.users = args.users.split(",")
else:
    args.users = []

# some useful functions (strip whitespaces, return custom position from a line)
def normalize_whitespace(string):
  return re.sub(r'(\s)\1{1,}', r'\1', string)

def giveme(s, position):
  lista = s.split(' ')
  return lista[position]

# define telnet connection parameters
HOST = "localhost"
PORT = "29523"

# initialize telnet connection
tn=telnetlib.Telnet(HOST,PORT)
#tn.set_debuglevel(9)
tn.read_until(':OpenVPN Management Interface',1)

tn.write('status\n')
output = tn.read_until('ROUTING TABLE',1)

total_lines = len(output.split("\n"))
os.system('clear')

i = 0
total_users = 0

print('{:<22}{:<20}{:<15}{:<15}{:<20}'.format('VPN USER', 'CONNECTED FROM', 'BYTES REC', 'BYTES SENT', 'CONNECTED SINCE'))
print('-----------------------------------------------------------------------------------------------')

output = output.split("\r\n")[4:-1]
for item in sorted(output):
     line = item.strip()
     line = normalize_whitespace(line)
     line_s = line.split(',')

     if len(line_s) == 5:
         if args.users:
             for user in args.users:
                 if user in line_s[0]:
                     print('{:<22}{:<20}{:<15}{:<15}{:<20}'.format(line_s[0],line_s[1].split(':')[0],line_s[2],line_s[3],line_s[4]))
                     total_users = total_users + 1
         else:
             print('{:<22}{:<20}{:<15}{:<15}{:<20}'.format(line_s[0],line_s[1].split(':')[0],line_s[2],line_s[3],line_s[4]))
             total_users = total_users + 1

print('-----------------------------------------------------------------------------------------------')
print('Connected VPN users: {:<5}\n'.format(total_users))

