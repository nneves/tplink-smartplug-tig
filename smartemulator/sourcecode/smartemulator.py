#!/usr/bin/python
#!/usr/bin/env python2
#
# TP-Link Wi-Fi Smart Plug (Emulator)
# Emulate TP-Link HS-100 or HS-110

import socket
import argparse
import sys
import signal
from struct import pack

def signal_handler(sig, frame):
    print('\nCTRL+C detected, process will exit!')
    sys.exit(0)
signal.signal(signal.SIGINT, signal_handler)

version = 0.1

# Predefined Smart Plug Commands
# For a full list of commands, consult tplink_commands.txt
commands = {'info'     : '{"system":{"get_sysinfo":{}}}',
			'on'       : '{"system":{"set_relay_state":{"state":1}}}',
			'off'      : '{"system":{"set_relay_state":{"state":0}}}',
			'cloudinfo': '{"cnCloud":{"get_info":{}}}',
			'wlanscan' : '{"netif":{"get_scaninfo":{"refresh":0}}}',
			'time'     : '{"time":{"get_time":{}}}',
			'schedule' : '{"schedule":{"get_rules":{}}}',
			'countdown': '{"count_down":{"get_rules":{}}}',
			'antitheft': '{"anti_theft":{"get_rules":{}}}',
			'reboot'   : '{"system":{"reboot":{"delay":1}}}',
			'reset'    : '{"system":{"reset":{"delay":1}}}',
			'energy'   : '{"emeter":{"get_realtime":{}}}'
}

# Encryption and Decryption of TP-Link Smart Home Protocol
# XOR Autokey Cipher with starting key = 171
def encrypt(string):
	key = 171
	result = pack('>I', len(string))
	for i in string:
		a = key ^ ord(i)
		key = a
		result += chr(a)
	return result

def decrypt(string):
	key = 171
	result = ""
	for i in string:
		a = key ^ ord(i)
		key = ord(i)
		result += chr(a)
	return result

port = 9999
error = '{"error":"unkown command"}'
# ./tplink_smartplug.py -t 127.0.0.1 -c info
info = '{"system":{"get_sysinfo":{"sw_ver":"1.5.4 Build 180815 Rel.121440","hw_ver":"2.0","type":"IOT.SMARTPLUGSWITCH","model":"HS110(EU)","mac":"11:22:33:44:55:66","dev_name":"Smart Wi-Fi Plug With Energy Monitoring","alias":"Smartplug Emulator","relay_state":1,"on_time":97515,"active_mode":"none","feature":"TIM:ENE","updating":0,"icon_hash":"","rssi":-62,"led_off":0,"longitude_i":-79362,"latitude_i":370122,"hwId":"044A516EE63C875F9458DA2511223344","fwId":"00000000000000000000000000000000","deviceId":"80067C211A62B17A84E54282982127F311223344","oemId":"1998A14DAA86E4E001FD7CAF11223344","next_action":{"type":-1},"err_code":0}}}'
# ./tplink_smartplug.py -t 127.0.0.1 -c energy
energy = '{"emeter":{"get_realtime":{"voltage_mv":240985,"current_ma":671,"power_mw":95376,"total_wh":2602,"err_code":0}}}'
# ./tplink_smartplug.py -t 127.0.0.1 -j "{\"system\":{\"get_sysinfo\":null},\"emeter\":{\"get_realtime\":{}}}"
info_energy = '{"system":{"get_sysinfo":{"sw_ver":"1.5.4 Build 180815 Rel.121440","hw_ver":"2.0","type":"IOT.SMARTPLUGSWITCH","model":"HS110(EU)","mac":"11:22:33:44:55:66","dev_name":"Smart Wi-Fi Plug With Energy Monitoring","alias":"Smartplug Emulator","relay_state":1,"on_time":97320,"active_mode":"none","feature":"TIM:ENE","updating":0,"icon_hash":"","rssi":-60,"led_off":0,"longitude_i":-79362,"latitude_i":370122,"hwId":"044A516EE63C875F9458DA2511223344","fwId":"00000000000000000000000000000000","deviceId":"80067C211A62B17A84E54282982127F311223344","oemId":"1998A14DAA86E4E001FD7CAF11223344","next_action":{"type":-1},"err_code":0}},"emeter":{"get_realtime":{"voltage_mv":240985,"current_ma":671,"power_mw":95376,"total_wh":2602,"err_code":0}}}'

try:
	# Create a TCP/IP socket
	sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	server_address = ('0.0.0.0', port)
	print >>sys.stderr, '-> starting up on %s port %s' % server_address
	sock.bind(server_address)

	# Listen for incoming connections
	sock.listen(1)

	while True:
		# Wait for a connection
		print >>sys.stderr, '-> waiting for a connection'
		connection, client_address = sock.accept()
		try:
			print >>sys.stderr, '-> connection from', client_address
			# Receive the data in small chunks and retransmit it
			while True:
				data = connection.recv(1024)
				decrypted_data = decrypt(data)
				if data:
					print >>sys.stderr, '=> received:\n%s' % decrypted_data
					send_data = ''
					if '\"emeter\"' in decrypted_data and '\"get_realtime\"' in decrypted_data and '\"system\"' in decrypted_data and '\"get_sysinfo\"' in decrypted_data:
						send_data = info_energy
					elif '\"system\"' in decrypted_data and '\"get_sysinfo\"' in decrypted_data:
						send_data = info
					elif '\"emeter\"' in decrypted_data and '\"get_realtime\"' in decrypted_data:
						send_data = energy
					else:
						send_data = error
					connection.sendall(encrypt(send_data))
					print >>sys.stderr, '<= sending data to the client:\n%s' % send_data
				else:
					print >>sys.stderr, '* no more data from', client_address
					break				
		finally:
			# Clean up the connection
			connection.close()
except socket.error:
	quit("Could not run tcp server on port " + str(port))
