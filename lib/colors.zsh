#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- colors.zsh -- Generates color variables
# -----------------------------------------------------------------------------------
_debug_load

# Put standard ANSI color codes in shell parameters for easy use.
# Note that some terminals do not support all combinations.

emulate -L zsh

typeset -Ag color colour

color=(
# Codes listed in this array are from ECMA-48, Section 8.3.117, p. 61.
# Those that are commented out are not widely supported or aren't closely
# enough related to color manipulation, but are included for completeness.

# Attribute codes:
  00 none                 # 20 gothic
  01 bold                 # 21 double-underline
  02 faint                  22 normal
  03 italic                 23 no-italic         # no-gothic
  04 underline              24 no-underline
  05 blink                  25 no-blink
# 06 fast-blink           # 26 proportional
  07 reverse                27 no-reverse
# 07 standout               27 no-standout
  08 conceal                28 no-conceal
# 09 strikethrough        # 29 no-strikethrough

# Font selection:
# 10 font-default
# 11 font-first
# 12 font-second
# 13 font-third
# 14 font-fourth
# 15 font-fifth
# 16 font-sixth
# 17 font-seventh
# 18 font-eighth
# 19 font-ninth

# Text color codes:
  30 black                  40 bg-black
  31 red                    41 bg-red
  32 green                  42 bg-green
  33 yellow                 43 bg-yellow
  34 blue                   44 bg-blue
  35 magenta                45 bg-magenta
  36 cyan                   46 bg-cyan
  37 white                  47 bg-white
# 38 iso-8316-6           # 48 bg-iso-8316-6
  39 default                49 bg-default

# Other codes:
# 50 no-proportional
# 51 border-rectangle
# 52 border-circle
# 53 overline
# 54 no-border
# 55 no-overline
# 56 through 59 reserved

# Ideogram markings:
# 60 underline-or-right
# 61 double-underline-or-right
# 62 overline-or-left
# 63 double-overline-or-left
# 64 stress
# 65 no-ideogram-marking

# Bright color codes (xterm extension)
  90 bright-gray            100 bg-bright-gray
  91 bright-red             101 bg-bright-red
  92 bright-green           102 bg-bright-green
  93 bright-yellow          103 bg-bright-yellow
  94 bright-blue            104 bg-bright-blue
  95 bright-magenta         105 bg-bright-magenta
  96 bright-cyan            106 bg-bright-cyan
  97 bright-white           107 bg-bright-white
)

# A word about black and white:  The "normal" shade of white is really a
# very pale grey on many terminals; to get truly white text, you have to
# use bold white, and to get a truly white background you have to use
# bold reverse white bg-xxx where xxx is your desired foreground color
# (and which means the foreground is also bold).

# Map in both directions; could do this with e.g. ${(k)colors[(i)normal]},
# but it's clearer to include them all both ways.
local k
for k in ${(k)color}; do color[${color[$k]}]=$k; done

# Add "fg-" keys for all the text colors, for clarity.
for k in ${color[(I)[39]?]}; do color[fg-${color[$k]}]=$k; done
# This is inaccurate, but the prompt theme system needs it.

for k in grey gray; do
  color[$k]=${color[black]}
  color[fg-$k]=${color[$k]}
  color[bg-$k]=${color[bg-black]}
done

# Assistance for the colo(u)r-blind.

for k in '' fg- bg-; do
  color[${k}bright-grey]=${color[${k}bright-gray]}
done

colour=(${(kv)color})	# A case where ksh namerefs would be useful ...

# The following are terminal escape sequences used by colored prompt themes.

local lc=$'\e[' rc=m	# Standard ANSI terminal escape values
typeset -Hg reset_color bold_color
reset_color="$lc${color[none]}$rc"
bold_color="$lc${color[bold]}$rc"

# Foreground

typeset -AHg fg fg_bold fg_no_bold
for k in ${(k)color[(I)fg-*]}; do
    fg[${k#fg-}]="$lc${color[$k]}$rc"
    fg_bold[${k#fg-}]="$lc${color[bold]};${color[$k]}$rc"
    fg_no_bold[${k#fg-}]="$lc${color[normal]};${color[$k]}$rc"
done

# Background

typeset -AHg bg bg_bold bg_no_bold
for k in ${(k)color[(I)bg-*]}; do
    bg[${k#bg-}]="$lc${color[$k]}$rc"
    bg_bold[${k#bg-}]="$lc${color[bold]};${color[$k]}$rc"
    bg_no_bold[${k#bg-}]="$lc${color[normal]};${color[$k]}$rc"
done
