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

class DigestController < ApplicationController
	unloadable

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
				message += "<p>%d %s sent.<br />%s</p>" % [
					@test.length, 
					@test.length == 1 ? "email was" : "emails were",
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
		if not session.nil?
			redirect_to :controller => 'settings', :action => 'plugin', :id => 'digest'
		end
	end
	
	def send_digest(options={})
		digest_send("options", options)
	end
	
	def send_all
		digest_send "all"
	end

	def test_email
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
