#!/usr/bin/env ruby
# https://github.com/caseyhoward/nokogiri-plist
require 'plist'

# /apps/gnome-terminal/profiles/Default
#  -> background_color
#  -> bold_color
#  -> foreground_color
#  -> palette

def convert_to_key(real_color)
  return "%02X" % (real_color * 255)
end

def gconf2_command(gconf_key, gconf_type, gconf_value)
  return "gconftool-2 --set /apps/gnome-terminal/profiles/Default/#{gconf_key} --type #{gconf_type} \"#{gconf_value}\""
end

def get_rgb(doc_hash)
  red   = convert_to_key(doc_hash["Red Component"])
  green = convert_to_key(doc_hash["Green Component"])
  blue  = convert_to_key(doc_hash["Blue Component"])

  return "##{red}#{green}#{blue}"
end

ARGV.each do |iterm_theme|
  doc            = Plist::parse_xml(iterm_theme)
  keys_to_export = Hash.new
  keys_to_export["palette"] = Array.new(16)

  doc.keys.each do |doc_key|
      if doc_key =~ /Ansi \d+ Color/
          slot  = doc_key.scan(/Ansi (\d+) Color/)[0][0].to_i
          hex   = get_rgb(doc[doc_key])
          keys_to_export["palette"][slot] = hex
      end

      if doc_key =~ /Background Color/
          # This goes directly to background_color
          hex   = get_rgb(doc[doc_key])
          keys_to_export["background_color"] = hex
      end

      if doc_key =~ /Foreground Color/
          # This goes directly to foreground_color
          hex   = get_rgb(doc[doc_key])
          keys_to_export["foreground_color"] = hex
      end

      if doc_key =~ /Bold Color/
          # This goes directly to bold color
          hex   = get_rgb(doc[doc_key])
          keys_to_export["bold_color"] = hex
      end
  end

  puts "# " + iterm_theme
  puts gconf2_command("foreground_color", "string", keys_to_export["foreground_color"])
  puts gconf2_command("background_color", "string", keys_to_export["background_color"])
  puts gconf2_command("bold_color", "string", keys_to_export["bold_color"])
  puts gconf2_command("palette", "string", keys_to_export["palette"].join(':'))
end
