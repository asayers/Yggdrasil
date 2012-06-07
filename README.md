Yggdrasil
=========

A simple yet powerful tweetbot written in ruby.

Overview
--------

This tweetbot listens for direct messages (DMs) sent to a particular twitter
account. When the tweetbot recieves a DM, the message is parsed as a `command
args` string (not case sensative). Some relevant code is executed, and a DM is
sent back in response. The beauty of this system is that a twitter account can
only recieve DMs from accounts which it is following; therefore the only people
who can use the tweetbot are the people whose accounts it is following.

Schematic
---------

The parts you will need to modify are:

 - The admin twitter account: this is the account to which the tweetbot will
   send DMs when errors occur etc.
 - The consumer key/secret: these are the OAuth credentials for your tweetbot's
   twitter account.
 - The access token/secret: these are the OAuth credentials for the application
   you will register this tweetbot as.
 - The rules for responding to direct messages.

The admin account can be set at the top of the source. The OAuth stuff is best
set in ~/.netrc, under the machine names "yggdrasil-consumer" and
"yggdrasil-access".

The behaviours are defined by the Parser class. The commands to which the
tweetbot can respond are simply the methods of this class. When a DM arrives,
the relevant method is called with the args passed in as an array. If the
method returns an array of strings, each string will be sent as a response DM
to the user who sent the request. You can also access the instance variable
@reciepient from within these methods if you need information about the user
(eg. for implementing permissions, for personalising the response, or in case a
DM needs to be sent before the method is finished executing).

Example:

```ruby
class Parser
     def marco args
          ["Polo!"]
     end

     def my_name_is args
          args.each { |s| s.capitalize! }
          name = args.join(" ")
          ["Nice to meet you, #{name}!"]
     end
end
```

This should yeild the following behaviour:

     User: Marco
     Bot:  Polo!
     User: My_name_is alex sayers
     Bot:  Nice to meet you, Alex Sayers!

To Do
-----

 - Auto-split long DMs (>140 chars) into multiple, rather than just truncating
 - Handle exceptions better (ie. without dying)
 - Fork off a new process every time the parse method is called
 - Only downcase the command. The args sould be case-sensative.

Authors
-------

Alex Sayers (alex.sayers@gmail.com)

Licence
-------

     Copyright (c) 2012, Alex Sayers
     All rights reserved.

     Redistribution and use in source and binary forms, with or without
     modification, are permitted provided that the following conditions are met:

     1. Redistributions of source code must retain the above copyright notice, this
        list of conditions and the following disclaimer.
     2. Redistributions in binary form must reproduce the above copyright notice,
        this list of conditions and the following disclaimer in the documentation
        and/or other materials provided with the distribution.
     3. Neither the name of the organisation nor the names of its contributors may
        be used to endorse or promote products derived from this software without
        specific prior written permission.

     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
     ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
     WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
     DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY DIRECT,
     INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
     DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
     LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
     OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
     ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
