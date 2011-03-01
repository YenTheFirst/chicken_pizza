
require 'socket'
class MPD
	def initialize(url,port=6600)
		@url=url
		@port=port
	end
	def all_tracks
		puts "loading tracz"
		list_all_info.slice_before(/^file/).map {|line| Hash[*line.map {|entry| entry.match(/([^:]*): (.*)/)[1,2]}.flatten]}  
	end
	def list_all_info
		send_command("listallinfo")
	end

	def send_command(cmd)
		tcp=TCPSocket.new(@url,@port)
		tcp.set_encoding("UTF-8")
		tcp.gets #ensure it's "OK"
		tcp.puts cmd
		all=[]
			#this is a little unsafe, it depends on the other end to close the connection
		until all.last=="OK"
			all<< tcp.gets.chomp
		end
		tcp.close
		all[0..-2]
	end
end