#require 'mpd_driver.rb'
load 'mpd_driver.rb'
$mpd=MPD.new("chicken.local")

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
	all_tracks.select do |entry|
		all_q.all? do |query|
			entry.any? do |key,value|
				query === value
			end
		end
	end.to_json
end
get '/filter' do
	available={}
	tracks=all_tracks.clone
	params[:filters].each do |(tag,selected_choices)|
		available[tag]=tracks.map {|entry| entry[tag]}.uniq
		tracks.select! {|entry| selected_choices.include? entry[tag]}
	end
	available["Tracks"]=tracks
	available.to_json
end