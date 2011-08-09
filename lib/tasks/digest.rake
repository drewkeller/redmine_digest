# redMine - project management software
# Copyright (C) 2011 Drew Keller
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

desc <<-END_DESC
A plugin to send email digests of project activity. This plugin must be called by a scheduler (cronjob, Windows task, etc.).

Available options:
  * start    => number of days ago to start (defaults to 1, i.e. yesterday)
  * days     => number of days to summarize (defaults to 1)
  * project  => id or identifier of project (defaults to all projects that are enabled)

Example:
  rake redmine:send_digest days=7 RAILS_ENV="production"
END_DESC

require 'rake'
require File.expand_path(File.dirname(__FILE__) + "/../../../../../config/environment")
#require "mailer"
#require "digestmailer"

namespace :redmine do
	task :send_digest, :environment, :project, :start, :days do |t, args|
		options = {}
		args.with_defaults(:project => nil, :start => nil, :days => nil, :environment => "production")
		ENV['environment'] = args[:environment]
		options[:project] = ENV['project'] if (ENV['project'] || args[:project])
		options[:start] = ENV['start'].to_i if (ENV['start'] || args[:start])
		options[:days] = ENV['days'].to_i if (ENV['days'] || args[:days])

		DigestMailer.digests(options)
		puts "Digest done."
	end
end
