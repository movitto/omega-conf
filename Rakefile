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

desc 'Ensure symlinks are properly setup'
task 'symlinks' do
  unless File.symlink?('recipes/omega/files/public')
    FileUtils.rm_rf('recipes/omega/files/public') if File.exists?('recipes/omega/files/public')
    File.symlink('../../../release', 'recipes/omega/files/public')
  end

  unless File.symlink?('recipes/omega/files/private')
    FileUtils.rm_rf('recipes/omega/files/private') if File.exists?('recipes/omega/files/private')
    File.symlink('../../../private', 'recipes/omega/files/private')
  end
end

desc 'Run the installation/configuration process'
task 'install' => 'symlinks' do
  system('puppet --modulepath=recipes recipes/omega/omega.pp')
end

desc 'Run the mediawiki installation/configuration process'
task 'mediawiki' => 'symlinks' do
  system('puppet --modulepath=recipes recipes/omega/mediawiki.pp')
end

desc 'Verify the installation/configuration process'
task 'verify' do
  system('puppet --modulepath=recipes recipes/omega/verify.pp')
end
