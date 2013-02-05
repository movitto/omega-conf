# omega-conf project Rakefile
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require "rake/packagetask"

Rake::PackageTask.new("omega-conf", "0.2.0") do |p|
  p.need_tar = true
  p.package_files.include("**/*")
  p.package_files.exclude("pkg/**/*")
end
