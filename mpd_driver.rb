
require 'socket'
class MPD
	def initialize(url,port=6600)
		@url=url
		@port=port
	end
	def all_tracks
		puts "loading tracz"
		list_all_info.slice_before(/^file/).map {|line| line_to_hash(line)}
	end
	def list_all_info
		send_command("listallinfo")
	end
	def status
		res=line_to_hash(send_command("status"))
		res["queue_version"]=res.delete("playlist")
		res["queue_length"]=res.delete("playlistlength")
		res
	end
	def queue
		send_command("playlistinfo").slice_before(/^file/).map {|line| line_to_hash(line)}
	end
	def add(fname)
		r=send_command("addid \"#{fname.gsub('"','\"')}\"")
		r[0].match(/^Id: (\d+)/) ? $1 : nil #maybe raise error instead?
	end
	def line_to_hash(line)
		Hash[*line.map {|entry| entry.match(/([^:]*): (.*)/)[1,2]}.flatten]
	end
	def send_command(cmd)
		tcp=TCPSocket.new(@url,@port)
		tcp.set_encoding("UTF-8")
		tcp.gets #ensure it's "OK"
		tcp.puts cmd
		all=[]
			#this is a little unsafe, it depends on the other end to close the connection
		until all.last=="OK" or all.last =~ /^ACK/
			all<< tcp.gets.chomp
		end
		tcp.close
		if all.last=="OK"
			all[0..-2] #pull off the ok
		else
			[all.last]
		end
	end
end