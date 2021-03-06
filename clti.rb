#!/usr/bin/env ruby
#
# clti - the command line timer
#
# Return values:
#  0 success
#  2 user pressed 'q'
#
#
#   Copyright 2015 Michael Ulm
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.

#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'optparse'
require 'time'
require 'yaml'
begin
  require 'figlet'
  UseFiglet = true
rescue LoadError
  UseFiglet = false
end
begin
  require 'chronic_duration'
  UseChronicDuration = true
rescue LoadError
  UseChronicDuration = false
end

DefaultFontDirectory = "~/fonts/figlet_fonts/contributed"
DefaultFont = "banner3"
FontEnding = "flf"
SleepTime = 0.1

DefaultConfigLocations = [File.join("~", ".cltirc"), File.join("~", ".config", "clti", "cltirc")]

def simple_time_parser(ar)
  duration = 0
  nr = (ar.size + 1) / 2
  nr.times do |i|
    d = ar[2 * i].to_i
    case ar[2 * i + 1].to_s.downcase
    when /^h/ then duration += 3600 * d
    when /^m/ then duration += 60 * d
    when /^s/ then duration += d
    else
      duration += 60 * d
    end
  end

  duration
end

class Clti
  attr_reader :font_name, :font_directory, :filename, :command
  attr_writer :filename, :font_name, :font_directory, :command

  def initialize
    @filename = nil
    @font_name = nil
    @font_directory = nil
    @figlet = nil
    @command = nil
  end

  def read
    if @filename
      read_file(@filename)
    else
      DefaultConfigLocations.each do |path|
        config_name = File.expand_path(path)
        if read_file config_name
          @filename = config_name
          break
        end
      end
    end

    if UseFiglet
      unless @filename
        @font_name ||= DefaultFont
        @font_directory ||= DefaultFontDirectory
      end

      @font = Figlet::Font.new(File.expand_path(File.join(@font_directory, "#{@font_name}.#{FontEnding}")))
      @figlet = Figlet::Typesetter.new(@font, :smush => false)
    end
  end

  def read_file(filename)
    return false unless File.exists?(filename)

    doc = YAML.load(File.read(filename))
    @font_name ||= (doc.include?("font") ? doc["font"] : DefaultFont)
    @font_directory ||= (doc.include?("font_directory") ? doc["font_directory"] : DefaultFontDirectory)
    @command ||= doc["command"]
    true
  end

  def set(ar)
    time_str = ar.join(' ')
    time_str << ' m' if ar.size == 1 # default is time in minutes
    if UseChronicDuration
      @sec = ChronicDuration.parse time_str
    else
      @sec = simple_time_parser(ar)
    end
  end

  def get_key
    key = nil
    system('stty raw -echo')
    key = STDIN.read_nonblock(1) rescue nil
    system('stty -raw echo')
    key
  end

  def pause(remaining)
    puts "pausing - hit 'r' to resume, 'q' to quit"
    while true
      sleep SleepTime
      case get_key
      when 'r'
        @t_stop = Time.now + remaining
        return
      when 'q'
        exit 2
      end
    end
  end

  def start
    t_start = Time.now
    display
    @t_stop ||= t_start + @sec

    while true
      sleep SleepTime
      t = Time.now
      case get_key
      when 'p'
        pause(@t_stop - t)
        t = Time.now
      when 'q'
        exit 2
      end
      break if t > @t_stop
      dt = (@t_stop - t).ceil
      if dt != @sec
        @sec = dt
        display
      end
    end

    @sec = 0
    display

    exec @command if @command
  end

  private

  def show_nr(nr)
    nr.to_s.rjust(2, '0')
  end

  def display
    hrmin, seconds = @sec.divmod(60)
    hours, minutes = hrmin.divmod(60)
    system "clear"
    str = "#{show_nr(hours)} : #{show_nr(minutes)} : #{show_nr(seconds)}"
    if UseFiglet
      puts @figlet[str]
    else
      system "clear" or system "cls" # to be a bit more portable
      puts str
    end
  end
end

def setup
  clti = Clti.new
  opt = OptionParser.new do |opts|
    opts.banner = "usage: clti [options] time\n  press 'p' to pause, 'q' to quit"

    opts.on("-c file", "--config file", "Set config file") do |filename|
      clti.filename = filename
    end

    opts.on("-f font", "--font font", "Set figlet font") do |font|
      clti.font_name = font
    end

    opts.on("-d dir", "--font-directory dir", "Set figlet font directory") do |dir|
      clti.font_directory = dir
    end

    opts.on("-x command", "--execute command", "Set command to execute after finishing uninterupted") do |command|
      clti.command = command
    end

    opts.on_tail("-h", "--help", "Show this message and exit") do
      puts opts
      exit 0
    end
  end
  opt.parse!(ARGV)

  if ARGV.empty?
    puts opt
    exit 0
  end

  clti.set ARGV
  clti.read
  clti
end

if $0 == __FILE__
  clti = setup
  clti.start
end
