#! /usr/bin/env ruby

require 'twitter'
require 'tweetstream'
require 'netrc'

######## Yggdrasil ########
# a Tweetbot by Alex Sayers
#
# Please refer to README.md for instructions for use. Note that this program
# will simply fail to start unless ~/.netrc contains the appropriate OAuth
# entries.
#
# To Do:
#  - Auto-split long DMs (>140 chars) into multiple, rather than just truncating
#  - Handle exceptions better (ie. without dying)
#  - Fork off a new process every time the parse method is called
#  - only downcase the command. The args sould be case-sensative.
#
# Copyright (c) 2012, Alex Sayers
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. Neither the name of the organisation nor the names of its contributors may
#    be used to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


# Load in Twitter OAuth keys and tokens and stuff.
ADMIN             = "alexsayers"
C_KEY, C_SECRET   = Netrc.read["yggdrasil-consumer"]
A_TOKEN, A_SECRET = Netrc.read["yggdrasil-access"]

# This class contains all the behaviours for responding to different commands
# Each behaviour is given as a method, which is called with the arguments args
# and recipient.
#
# args:        an Array containing the arguments to the command
# recipient:   a String containing the screen name of the caller, in case we
#              need to respond manually
#
# Each method should return an Array of Strings, each of which will be sent as
# a separate DM to the recipient. I should really reimplement some of these in
# pure Ruby.
class Parser
     def initialize recipient
          @recipient = recipient
     end

     def time args
          t = Time.now
          ["It's #{t.ctime}"]
     end

     def update args
          # In this case in particular, the lack of threading prevents the
          # daemon from responding to new DMs for a while. Not great.
          # Short-term fix: I've extended `broadcast` to allow the sending
          # of DMs.
          # Note: passwordless sudo must be enabled for pacman.
          system("(sudo pacman -Sy; PACNO=$(($(pacman -Sup | wc -l) -1 )); broadcast #{@recipient} \"There are $PACNO packages to be upgraded\") &")
          ["Synching package databases with repositories..."]
     end

     def upgrade args
          # TODO: I need to pass the option to auto-yes the upgrade
          # Note: passwordless sudo must be enabled for pacman. (sudoers: [user] ALL=(ALL) NOPASSWD: pacman *)
          #system('(broadcast "Starting full system update"; sudo pacman -Syu; broadcast "Update complete") &')
          #["Beginning full system update"]
          ["Unattended upgrades are a work-in-progress"]
     end

     def todo args
          # This should deliver a single string instead of an array once I've got auto-splitting working 
          `todo #{args.join(" ")}`.split("\n")
     end

     def alert args
          # Use dzen2 to flash a message at the top of the screen. Returns nothing
          system("alert \"#{args.join(' ')}\"")
          nil
     end

     def info args
          info = ""
          ["Battery: "+`battery`, "Volume: "+`volume`, "Wifi: "+`wifi`, "Unread: "+`mail_check`].each do |out|
               info << out.split("\n")[0].gsub(/<[^>]*>/,"")+"\n"
          end
          [info]
     end

     def say args
          # Use the say command to speak args out loud. Install espeak and create a symlink to it called "say"
          system("say \"#{args.join(" ")}\"")
          nil
     end

     def help args
          commands = ""
          self.methods.each do |m|
               commands << (m.to_s + ", ") unless Object.methods.include?(m)
          end
          ["Available commands: #{commands[0...(commands.size-2)]}"]
     end

     def exec args
          # Simply execute args and return the result (potentially dangerous, obvs)
          #[`#{args.join(" ")}`]
          ["Arbitrary code execution disabled (for obvious reasons)"]
     end

     def kill args
          # Send the message now, 'cause otherwise we'll never get round to it
          dm("Killing Yggdrasil response bot...", @recipient)
          $client.stop
     end
end

# Send a Direct Message. Shortens the message to 140 chars and checks it's not
# identical to the last message to be sent. This avoids most Twitter errors.
#
# message:     a String containing the contents of the DM
# recipient:   a String, the screen name of recipient. Defaults to ADMIN
#
# Returns the message which was eventually sent.
def dm(message, recipient=ADMIN)
     message = message[0...140]                   # Shrink message to 140 chars
     message.next! if message == $last_post       # Ensure we don't double-post
     Twitter.direct_message_create(recipient, message[0...140])     # Lift-off!
     $last_post = message
end

# Takes in a message, splits it along the first whitespace into a command
# String and an args Array, and then passes the command to an instance of
# the Parser class for handling (this usually involves an unholy mashup of
# ruby and bash).
#
# message:   a String containing the content of a recieved DM
# recipient: the screen name of the correspondant (in case I
#            need to send a reply from within this method)
#
# Returns an Array of Strings, each of which is to be sent as a separate DM
#
# I should really have these things splitting off separate processes or
# threads, to allow the runloop to get back to responding to new DMs. I
# should also really ensure that args doesn't contain any ';'s or '`'s or
# '$'s or anything that might allow arbitrary code execution.
def parse(message, recipient)
     args = message.split(" ")
     command = args.delete_at(0)
     # Check that command is one of Parser's available methods before instantiating
     if Parser.method_defined?(command) and not Object.method_defined?(command)
          Parser.new(recipient).send(command, args)
     end
end

### Entry Point

# Configure the various Twitter gems
Twitter.configure do |config|
  config.consumer_key       = C_KEY
  config.consumer_secret    = C_SECRET
  config.oauth_token        = A_TOKEN
  config.oauth_token_secret = A_SECRET
end
TweetStream.configure do |config|
  config.consumer_key       = C_KEY
  config.consumer_secret    = C_SECRET
  config.oauth_token        = A_TOKEN
  config.oauth_token_secret = A_SECRET
end

# Start the client as a normal process:
$client = TweetStream::Client.new
# Or as a daemon:
#$client = TweetStream::Daemon.new('tracker')

# So we can avoid respoding to our own messages
$me = Twitter.user.screen_name

# Handles DMs
$client.on_direct_message do |direct_message|
     # Extracts information from the DM
     recipient = direct_message.user.screen_name
     message = direct_message.text.downcase

     # Parses the message and determines the response
     response = parse(message, recipient) unless recipient == $me
     puts "#{recipient}: #{message}"

     # Sends the response
     unless response.nil? or response.empty?
          response.each do |text|
               dm(text, recipient)
          end
     end
end

# Not really doing anything with mentions. Errors fire off a warning to ADMIN via DM.
$client.on_timeline_status do |status|
  print "timeline status: "
  puts status.text
end
$client.on_error do |message|
  puts "Error: #{message}"
  dm(message)
end

# The hash ensures that we don't double-post
$last_post = ""
dm("Coming online: #{self.hash}")
# Begin the runloop (which watches the stream and calls handler methods as
# necessary) as a normal process:
$client.userstream
# Or as a daemon:
#$client.track('yggdrasil')

# Final words
dm("Response bot going down.")

### EOF
