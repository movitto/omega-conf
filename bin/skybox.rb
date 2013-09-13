#!/usr/bin/ruby
# copy a vegastrike skybox cube (/usr/share/vegatrike/textures/backgrounds)
# to a specified directory and convert it into an omega renderable skybox

require 'fileutils'
VG_CUBE=ARGV.shift
OM_PATH=ARGV.shift

cube = VG_CUBE.split(File::SEPARATOR).last
cuben = File.basename cube

FileUtils.mkdir_p OM_PATH unless File.directory? OM_PATH
FileUtils.cp(VG_CUBE, OM_PATH)
Dir.chdir OM_PATH
`convert #{cube} #{cuben}.png`
FileUtils.mv "#{cuben}-0.png", "px.png"
FileUtils.mv "#{cuben}-1.png", "nx.png"
FileUtils.mv "#{cuben}-2.png", "pz.png"
FileUtils.mv "#{cuben}-3.png", "nz.png"
FileUtils.mv "#{cuben}-4.png", "py.png"
FileUtils.mv "#{cuben}-5.png", "ny.png"
File.write("source", "from #{VG_CUBE}")
