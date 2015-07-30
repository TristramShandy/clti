#!/usr/bin/env ruby
#
# clti - the command line timer
#
# TODO: 
#   * clock based countdown
#   * command line params for Font directory and font
#   * more fine grained time options
#   * support for some action after time has run out

require 'figlet'
require 'time'

DefaultFontDirectory = "/home/michael/sources/figlet_fonts/contributed"
DefaultFont = "banner3"
FontEnding = "flf"

def usage
  puts "usage: clti time"
  puts "  a command line timer. Time is given in minutes"
end

def show_nr(nr)
  nr.to_s.rjust(2, '0')
end

def clti_display(nr, figlet)
  hrmin, seconds = nr.divmod(60)
  hours, minutes = hrmin.divmod(60)
  system "clear"
  puts figlet["#{show_nr(hours)} : #{show_nr(minutes)} : #{show_nr(seconds)}"]
end

def clti(nr)
  t_start = Time.now
  font = Figlet::Font.new(File.join(DefaultFontDirectory, "#{DefaultFont}.#{FontEnding}"))
  figlet = Figlet::Typesetter.new(font, :smush => false)
  sec = nr * 60
  clti_display sec, figlet
  t_stop = t_start + sec

  while true
    sleep 0.1
    t = Time.now
    break if t > t_stop
    dt = (t_stop - t).ceil
    if dt != sec
      clti_display dt, figlet
      sec = dt
    end
  end

  clti_display 0, figlet
end

if $0 == __FILE__
  if ARGV.empty?
    usage
    exit(0)
  end

  clti(ARGV[0].to_i)
end
