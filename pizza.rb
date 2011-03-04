#require 'mpd_driver.rb'
require './mpd_driver.rb'
$mpd=MPD.new("chicken.local")
#SECTION: other functions
get '/' do
	redirect '/index.html'
end
get '/status' do
	$mpd.status.to_json
end
put '/reload_db' do
	$mpd.send_command("update")
	$cached_tracks=nil
	'["ok"]'
end
	#meant to be used with the file_uploader javascript thing
require 'tempfile'
post '/upload_file' do
	begin
		fname=params[:qqfile]
		t=Tempfile.new(fname) do |f|
			f << request.env["rack.input"].read
		end
		artist,album = case fname.match(/\.[^.]*$/)[0].downcase #for the extension
			when ".mp3"
				Mp3Info.open(t.path) {|m| [m.tag["artist"],[m.tag["album"]]}
			when ".m4a",".mp4","m4v"
				m=MP4Info.open(t.path)
				[m.ART,m.ALB]
			when ".wav"
				[nil,nil] #NO METADATA ON WAV, I THINK
			when ".wma"
				m=WmaInfo.new(t.path)
				[m.tags["artist"],m.tags["album"] #UNTESTED, need wma with acceptable tags
			when ".aif"
				[nil,nil] #NO IDEA HERE, I don't think I have tagged aif files either
			when ".ogg"
				OggInfo.open(t.path) {|m| [m.tag["artist"],m.tag["album"]]}
			else
		end
	ensure
		t.close
		t.unlink
	end
	'{ "success": true }'
end
#SECTION: search functions
def all_tracks
	$cached_tracks ||= $mpd.all_tracks
end
get '/all_tracks' do
	all_tracks.to_json
end
get '/untagged/:tag' do
	all_tracks.select {|x| x[params[:tag]].nil?}.to_json
end
get '/search/:query' do
	all_q=params[:query].split(/\s/).map {|q| Regexp.new(q,true)} #it'll be converted to a regex anyway if we use match, and this is easier than downcasing everything for case insensitivity
	tracks=all_tracks.select do |entry|
		all_q.all? do |query|
			entry.any? do |key,value|
				query === value
			end
		end
	end
	res={"Tracks"=>tracks}
	params[:tags].each {|tag| res[tag] = tracks.map {|t| t[tag]}.uniq} if params[:tags]
	res.to_json
end

get '/filter' do
	available={}
	tracks=all_tracks.clone
		#WARNING: this function only works *correctly* if the hash is in the order it was in when presented to the application.
		#I don't know if this is standard behavior of get params, and if it is, how to guarantee it.
		#it does, however, seem to work for the moment
	params[:filters].each do |(tag,selected_choices)|
		available[tag]=tracks.map {|entry| entry[tag]}.uniq
		if (selected_choices) # if they gave us no choices, just return everything.
			if i=selected_choices.index("")
				selected_choices[i]=nil #for unknown albums
			end
			tracks.select! {|entry| selected_choices.include? entry[tag]}
		end
	end
	available["Tracks"]=tracks
	available.to_json
end
#SECTION: 'queue' functions. MPD calls these 'playlist' commands, but I'm differentiating here the live queue from saved playlists.
#all commands will return the current queue in JSON
#NOTE: all these will have to add a bit of thread/version safety
post '/queue/add' do
	#add params[:filename] to the queue
	#TODO: safety here
	safe_name=params[:filename].gsub('"','\"')
	res=$mpd.send_command("add \"#{safe_name}\"")
	if res.empty?
		'["ok"]'
	else
		res
	end
	#TODO: return
end
put '/queue/clear' do 
	$mpd.send_command("clear")
	#TODO: return
	'["ok"]'
end
delete '/queue/delete/:pos' do
	#TODO: safety here
	$mpd.send_command("delete "+params[:pos])
	#TODO: return
	'["ok"]'
end
put '/queue/move/:song_id' do
	$mpd.send_command("move #{params[:song_id]} #{params[:pos]}")
end
get '/queue/list' do
	$mpd.queue.to_json
end
#SECTION: 'playlist' functions
#SECTION: playback functions
post '/playback/next' do
	$mpd.send_command("next")
	'["ok"]'
end
post '/playback/previous' do
	$mpd.send_command("previous")
	'["ok"]'
end
put '/playback/pause' do
	#TODO: safety here
	$mpd.send_command("pause #{params[:state]}")
	'["ok"]'
end
put '/playback/play' do
	$mpd.send_command("play #{params[:pos]}")
	'["ok"]'
end
put '/playback/setvol' do
	$mpd.send_command("setvol #{params[:vol]}")
	'["ok"]'
end