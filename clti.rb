#!/usr/bin/env ruby
#
# clti - the command line timer
#
# Return values:
#  0 success
#  2 user pressed 'q'
#
# TODO: 
#   * support for some action after time has run out also in config file
#   * more fine grained time options (e.g. clti 10min 8sec  or so)
#   * alternative output methods instead of figlet

require 'optparse'
require 'figlet'
require 'time'
require 'yaml'

DefaultFontDirectory = "/home/michael/sources/figlet_fonts/contributed"
DefaultFont = "banner3"
FontEnding = "flf"
SleepTime = 0.1

DefaultConfigLocations = [File.join("~", ".cltirc"), File.join("~", ".config", "clti", "cltirc")]

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

    unless @filename
      @font_name ||= DefaultFont
      @font_directory ||= DefaultFontDirectory
    end

    @font = Figlet::Font.new(File.expand_path(File.join(@font_directory, "#{@font_name}.#{FontEnding}")))
    @figlet = Figlet::Typesetter.new(@font, :smush => false)
  end

  def read_file(filename)
    return false unless File.exists?(filename)

    doc = YAML.load(File.read(filename))
    @font_name ||= (doc.include?("font") ? doc["font"] : DefaultFont)
    @font_directory ||= (doc.include?("font_directory") ? doc["font_directory"] : DefaultFontDirectory)
    true
  end

  def set(ar)
    if ar[0][-1] == 's'
      @sec = ar[0].to_i
    else
      @sec = ar[0].to_i * 60
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
    puts @figlet["#{show_nr(hours)} : #{show_nr(minutes)} : #{show_nr(seconds)}"]
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
