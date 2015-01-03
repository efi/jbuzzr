jBuzzr
======

A minimalist JRuby module for using USB Buzz!™ controllers (the non-wireless flavour).

With cross-platform support thanks to "[javahidapi](https://code.google.com/p/javahidapi/)".

You will need Java and JRuby obviously.

Register for keypress events, switch on and off the buzzer lights and create awesome games! Here is how:

```ruby
require 'jbuzzr'

buzzer = JBuzzr.devices.values.first

p buzzer.lights.status
# => [false, false, false, false]

# let there be light
p buzzer.lights.update true, true, true, true
# => [true, true, true, true]

sleep 2

# ...except for player 1
p buzzer.lights.update false, nil, nil, nil
# => [false, true, true, true]

sleep 2

# ok, enough goofing around
buzzer.lights.update false, false, false, false

# now let's couple the lights to buzzer events 
buzzer.status.listeners << Proc.new do |event|
  if event[:button] == :buzzer
    light_command = [nil, nil, nil, nil]
    light_command[event[:controller]-1] = (event[:action] == :pressed)
    buzzer.lights.update *light_command
  end
end

# now let's prepare our main loop
looping = true

# let's also get debug output and add exit_on_yellow_button 
buzzer.status.listeners << Proc.new do |event|
  p event
  looping = !(event[:button] == :yellow)
end

while looping do
  sleep 1
end
```

Distributed under the "New BSD" license - because it's not the GPL and it is offered by javahidapi, too.
