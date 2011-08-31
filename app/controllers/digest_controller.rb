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
require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'

class DigestController < ApplicationController
	unloadable
	
	layout 'admin'

	def show_readme
		filename = 'README.rdoc'
		p = SM::SimpleMarkup.new
		h = SM::ToHtml.new
		f = File.dirname(__FILE__) + '/../../' + filename
		input_string = File.open(f, 'rb').read
		instructions = p.convert(input_string, h)
		@readme = { 
			:filename => filename, 
			:content => instructions 
		}
		respond_to do |format|
			format.html { render :template => 'settings/digest_readme.rhtml', :layout => 'admin',
			:locals => { :readme => @readme }}
		end
	end

	def digest_send(which, options={})
		raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
		# Force ActionMailer to raise delivery errors so we can catch it
		ActionMailer::Base.raise_delivery_errors = true
		begin
			case which
			when "options"
				@test = DigestMailer.digests(options)
				message = l(:notice_digests_sent)
			when "test"
				puts "User.current: %s" % User.current
				puts "User.current.mail: %s" % User.current.mail
				@test = DigestMailer.test(User.current)
				message = l(:notice_digest_sent_to, User.current.mail)
			when "all"
				@test = DigestMailer.digests
				message = l(:notice_digests_sent)
			else
				message "No case found for '%s'." % which
			end
			if @test.nil? or @test.empty?
				message += "<p>%s</p>" % "There was no resulting email."
			else
				message += "<p>%d %s processed.<br />%s</p>" % [
					@test.length, 
					@test.length == 1 ? "project was" : "projects were",
					@test.join("<br />")
				]
			end
			puts message
			flash[:notice] = message unless session.nil?
		rescue Exception => e
			puts e.message
			puts e.backtrace
			logger.error e.message, e.backtrace unless logger.nil?
			flash[:error] = l(:notice_digest_error, e.message) unless session.nil?
		end
		ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
		puts "Checking session state..."
		if not session.nil?
			puts "Redirecting to plugin settings."
			redirect_to :controller => 'settings', :action => 'plugin', :id => 'redmine_digest'
		else
			puts "A session was not found."
		end
	end
	
	def send_digest(options={})
		puts "Preparing to send digest..."
		puts options.inspect
		digest_send("options", options)
	end
	
	def send_all
		puts "Preparing to send digest for all projects."
		digest_send "all"
	end

	def test_email
		puts "Preparing to send test digest."
		digest_send "test"
	end

	def self.logger
		if RAILS_DEFAULT_LOGGER == nil
			#raise "No logger found"
		else
			return RAILS_DEFAULT_LOGGER
		end
		#ActionController::Base::logger
	end

end
