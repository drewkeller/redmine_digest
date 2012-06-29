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
if Rails::VERSION::MAJOR >= 3
	require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
else
	require File.expand_path(File.dirname(__FILE__) + "/../../../../../config/environment")
end

namespace :redmine do
	task :send_digest, :environment, :project, :start, :days, :debugging_messages do |t, args|
		if Rails::VERSION::MAJOR >= 3
			env = Rails.env
		else
			env = ENV
		end
		
		options = {}
		args.with_defaults(:project => nil, :start => nil, :days => nil, :environment => "production")
		env['environment'] = args[:environment]
		options[:project] = env['project'] if (env['project'] || args[:project])
		options[:start] = env['start'].to_i if (env['start'] || args[:start])
		options[:days] = env['days'].to_i if (env['days'] || args[:days])
		options[:debugging_messages] = env['debugging_messages'].to_i if (env['debugging_messages'] || args[:debugging_messages])

		DigestMailer.digests(options)
		puts "Digest done."
	end
end
