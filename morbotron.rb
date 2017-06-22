require 'twilio-ruby'
require 'rufus-scheduler'
require 'httparty'

account_sid = ENV["TWILIO_ACCOUNT_SID"]
auth_token = ENV["TWILIO_AUTH_TOKEN"]
@client = Twilio::REST::Client.new account_sid, auth_token

# set up our scheduler
scheduler = Rufus::Scheduler.new

def get_quote
  r = HTTParty.get('https://morbotron.com/api/random')
  if r.code == 200
    json= r.parsed_response
    _, episode, timestamp = json["Frame"].values
    image_url = "https://morbotron.com/meme/" + episode + "/" + timestamp.to_s
    caption = json["subtitles"].map{|subtitle| subtitle["Content"]}.join("/n")
    return image_url, caption
  end
end

def send_MMS
  media, body = get_quote
  begin
    @client.messages.create(
      body: body,
      media_url: media,
      to: '+12345678915',  # Replace with your phone number
      from: '+12345678912' # Replace with your Twilio number
    )
    puts "Message sent!"
  rescue Twilio::REST::RequestError => e
    puts e.message
  end
end

scheduler.every '30s' do
  send_MMS
end
scheduler.join
