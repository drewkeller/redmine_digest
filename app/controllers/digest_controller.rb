# redMine - project management software
# Copyright (C) 2011  Drew Keller
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

if Rails::VERSION::MAJOR < 3
	require 'rdoc/markup/simple_markup'
	require 'rdoc/markup/simple_markup/to_html'
end

class DigestController < ApplicationController
	unloadable
	
	layout 'admin'

	def show_readme
		filename = 'README.rdoc'
		f = File.dirname(__FILE__) + '/../../' + filename
		input_string = File.open(f, 'rb').read
		if Rails::VERSION::MAJOR >=3
			h = RDoc::Markup::ToHtml.new
			instructions = h.convert(input_string)
		else
			p = SM::SimpleMarkup.new
			h = SM::ToHtml.new
			instructions = p.convert(input_string, h)
		end
		@readme = { 
			:filename => filename, 
			:content => instructions 
		}
		respond_to do |format|
			format.html { render :template => 'settings/digest_readme.html.erb', :layout => 'admin',
			:locals => { :readme => @readme }}
		end
	end

	def digest_send(which, options={})
		is_session = @request.nil? && @_request.nil?
		is_session = !is_session
		if not is_session
			puts "setting request"
			@_request = ActionDispatch::Request.new(Rails.env)
		end
		if is_session
		raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
		# Force ActionMailer to raise delivery errors so we can catch it
		ActionMailer::Base.raise_delivery_errors = true
		end
		begin
			case which
			when "options"
				@test = DigestMailer.digests(options)
				message = l(:notice_digests_sent)
			when "test"
				dbg "User.current: %s" % User.current
				dbg "User.current.mail: %s" % User.current.mail
				@test = DigestMailer.test(User.current)
				message = l(:notice_digest_sent_to, User.current.mail)
			when "all"
				@test = DigestMailer.digests
				message = l(:notice_digests_sent)
			else
				message "No case found for '%s'." % which
			end
			if @test.nil? #or @test.empty?
				message += "<p>%s</p>" % "There was no resulting email."
			else
				message += "<p>%d %s processed.<br />%s</p>" % [
					@test.length, 
					@test.length == 1 ? "project was" : "projects were",
					@test.join("<br />")
				]
			end
			dbg message
			if is_session
				flash[:notice] = message
			end
		rescue Exception => e
			dbg e.message
			dbg e.backtrace
			if Rails::VERSION::MAJOR >= 3
				logger.error("%s: " % e.message) unless logger.nil?
			else
				logger.error e.message, e.backtrace unless logger.nil?
			end
			flash[:error] = l(:notice_digest_error, e.message) unless session.nil?
			if is_session
				flash[:error] = l(:notice_digest_error, e.message)
			else
				puts "Exception occurred: %s" % e.message
			end
		end
		if is_session
			ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
			redirect_to :controller => 'settings', :action => 'plugin', :id => 'redmine_digest'
		else
			puts "A session was not found."
		end
	end
	
	def send_digest(options={})
		dbg "Preparing to send digest..."
		dbg options.inspect
		digest_send("options", options)
	end
	
	def send_all
		dbg "Preparing to send digest for all projects."
		digest_send "all"
	end

	def test_email
		dbg "Preparing to send test digest."
		digest_send "test"
	end
	
	def dbg(message)
		if Setting.plugin_redmine_digest[:debugging_messages]
			puts message
			logger.info(message)
		else
			puts "debugging_messages: %s" % Setting.plugin_redmine_digest[:debugging_messages]
			logger.info("debugging_messages: %s" % Setting.plugin_redmine_digest[:debugging_messages])
		end
	end

	def self.logger
		if Rails::VERSION::MAJOR >= 3
			logger = Rails.logger
		else
			logger = RAILS_DEFAULT_LOGGER
		end
		return logger unless logger.nil?
		#ActionController::Base::logger
	end

end
