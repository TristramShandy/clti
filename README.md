#clti

The command line timer.

This is a simple timer to be called from the command line. Its design goal was
to make an easy to use, simple timer with no frills.

##Quick start

You need to have ruby installed. Then just put the `clti` file somewhere in your
path. Then you can do:

    clti 5                    # runs for 5 minutes, then stop
    clti 3 m 5 s              # runs for 3 minutes and 5 seconds
    clti -x 'play ping.ogg' 3 # runs for 3 minutes, then play the given sound file
    clti -h                   # short description of the command line parameters

When `clti` runs, you can press `p` to pause and then enter `r` to resume.

At any time you can enter `q` to quit.

##Fonts

If the `figlet` gem is installed, you can use the bigger figlet fonts to display
the remaining time. You may have to provide the figlet font directory manually
(with the `-d` switch) or through the configuration file.

##Parsing time durations

A simple time duration parser is provided with `clti`. You can feed it hours as
`h`, minutes as `m`, and seconds as `s`. Some examples of durations this parser
understands are:

    5                   # if only a number is given, it defaults to minutes
    15 s                # the number and its unit must be separated by whitespace
    3 s 4 h             # the values can be given in any order
    2 Minutes 8 Seconds # only the first letter (upper or lower case) of the unit is used

It is recommended to install the `chronic_duration` gem. If this is present it
is used to parse the time durations. Then you have more flexibility with the
input:

    5                       # if only a number is given, it defaults to minutes
    15s                     # the number and its unit don't have to be separated by whitespace
    2 minutes and 8 seconds # fill words are allowed
    2 wks 1 day 1 hr        # more time units for longer timers

For more information, see the
[chronic_duration](https://github.com/hpoydar/chronic_duration) gem
documentation.

##Configuration file

The tool will look at `~/.cltirc` and `~/.config/clti/cltirc` for a
configuration file. Alternatively, you can provide a configuration file with the
`-c` command line switch.

The configuration file is written in YAML format. In the configuration file, you
can give a default font, font directory and command. An example configuration
file could look like

    ---
    font: banner3
    font\_directory: '~/fonts/figlet\_fonts/contributed'
    command: "echo 'done'"

