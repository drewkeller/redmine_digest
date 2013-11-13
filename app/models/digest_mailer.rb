gem "actionmailer"
require "mailer"
#require "actionmailer"

class DigestMailer < Mailer
	unloadable

	if Rails::VERSION::MAJOR >= 3
		ActionMailer::Base.prepend_view_path(File.join(File.dirname(__FILE__), '../', 'views'))
	else
	self.instance_variable_get("@inheritable_attributes")[:view_paths] << RAILS_ROOT + "/vendor/plugins/redmine_digest/app/views"
	end

	#public :self.test
	def self.test(user)
		options = {}
		#project = Project.find :first
		#options[:project] = project[:name]
		options[:test_email] = user.mail
		log "Sending test email to %s." % user.mail

		return DigestMailer.digests(options)
	end

	def digest(project, recip_emails, body, days)
		if Rails::VERSION::MAJOR >= 3
			if l(:this_is_gloc_lib) == 'this_is_gloc_lib'
				subject = l(:mail_subject_digest, issues.size, days)
			else
				subject = l(:mail_subject_digest, :project => project, :count => body[:events].size, :days => days )
			end
			@body = body
			@date_from =body[:date_from]
			@date_to = body[:date_to]
			@test_email = body[:test_email]
			@days = body[:days]
			@start = body[:start]
			@events = body[:events]
			@events_by_day = body[:events_by_day]
			@params = @body[:params]
			mail(:to => recip_emails,
				 :subject => subject)
		else
			recipients recip_emails
			if l(:this_is_gloc_lib) == 'this_is_gloc_lib'
				subject l(:mail_subject_digest, issues.size, days)
			else
				subject l(:mail_subject_digest, :project => project, :count => body[:events].size, :days => days )
			end
			content_type "multipart/alternative"
			part :content_type => "text/plain", :body => render_message("digest.html.erb", body)
			part :content_type => "text/html", :body => render_message("digest.text.erb", body)
		end
		log 'Email sent.'
	end

	def self.fill_events(project, body={})
		#days = Setting.activity_days_default.to_i
		# From midnight of "from" (1st tick of the day)
		# To midnight of "to" + 1 (1st tick of the next day)
		# TODO: Do we need some error checking?
		start = body[:start]
		days = body[:days]
		params = {:from => Time.now}
		date_from = params[:from].to_date - start
		date_to = date_from + days
		body[:start] = start
		body[:date_to] = date_to
		body[:date_from] = date_from
		dbg "Summarizing: %s to %s (%d days)" % [ date_from.to_s, date_to.to_s, days]
		dbg l(:label_date_from_to, :start => format_date(date_to - days), :end => format_date(date_to-1))

		with_subprojects = params[:with_subprojects].nil? ? Setting.display_subprojects_issues? : (params[:with_subprojects] == '1')
		params["show_issues"] = 1
		params["show_changesets"] = 1
		params["show_news"] = 1
		params["show_documents"] = 1
		params["show_files"] = 1
		params["show_wiki_edits"] = 1
		user = User.find(:all, :conditions => ["admin='1'"]).first
		dbg "Warning: Could not find an admin user. Some events might not be visible to the anonymous user" if user.nil?
		activity = Redmine::Activity::Fetcher.new(user, :project => project,
			:with_subprojects => with_subprojects)
		activity.scope_select {|t| !params["show_#{t}"].nil?}
		#@activity.scope_select {:all}
		activity.scope = (user.nil? ? :default : :all) if activity.scope.empty?
		dbg "Activity.scope: %s" % activity.scope.inspect

		events = activity.events(date_from, date_to)
		dbg "events.count: %d" % events.count

		#if events.empty?
		body[:events] = events
		debug_events(events)
		body[:events_by_day] = events.group_by(&:event_date)
		puts "events_by_day days count: %d" % body[:events_by_day].count
		body[:params] = params
	rescue ActiveRecord::RecordNotFound
		logger.error "Record not found!"
		#render_404
	end
  
	def self.debug_events(events)
		return unless Setting.plugin_redmine_digest[:debugging_messages] || @debugging
		if events.blank?
			puts "No events found" 
			return
		end
		#puts "events.first.inspect: %s" % events.first.inspect
		puts
		puts "========================================"
		
		events_by_day = events.group_by(&:event_date)
		if events_by_day.blank?
			puts "Attempt to group by date resulted in no groups"
			events.each do |e|
				puts "       %s --- %s --- %s" % [format_time(e.event_datetime, false), e.event_type, e.event_title]
			end
			return
		end
		puts "events_by_day.keys: %s" % events_by_day.keys.sort.join(",")
		events_by_day.keys.sort.each do |day|
			puts "* day: %s" % day.to_s
			events_by_day[day].sort {|x,y| x.event_datetime <=> y.event_datetime }.each do |e|
				puts "       %s --- %s --- %s" % [format_time(e.event_datetime, false), e.event_type, e.event_title]
			end
		end
		puts
	end
  
	# Get all projects found with the plugin enabled or just the project specified
	def self.get_projects(project)
		projects = []
		if project.nil?
			dbg "Looking up projects to process..."
			p = EnabledModule.find(:all, :conditions => ["name = 'redmine_digest'"]).collect { |mod| mod.project_id }
			if p.length == 0
				log "No projects were found in the environment or no projects have digest enabled."
				return
			end
			condition = "id IN (" + p.join(",") + ")" 
			projects = Project.find(:all, :conditions => [condition])
			if projects.empty?
				log "Could not find matching project."
			end
			dbg "Found %i digestable projects out of %i total projects." % [projects.length, p.length]
		else
			dbg "Checking project '%s'" % project
			projects = Project.find(:all, 
				:conditions => ["id='%s' or identifier='%s'" % [project, project]])
			if projects.length == 0
				log "The specified project '%s' was not found." % [project]
			end
		end
		dbg "Projects to process: %s" % projects.join(", ")
		return projects
	end
  
	def self.get_recipients(project)
		recipients = []
		default = Setting.plugin_redmine_digest[:default_account_enabled]
		default = default.nil? ? true : default
		dbg "Default setting for whether digest is active for users: %s" % default.to_s

		members = Member.find(:all, :conditions => { :project_id => project[:id] }).each { |m|
			user = m.user

			# Skip groups
			if user.nil?
				next
			end

			puts "Found user %s" % user.id
			if user && user.active? && user.mail
				if user.digest_account.nil?
					active = default
				else
					active = user.digest_account.active?
				end
				recipients << user.mail if active
			end
		}
		dbg "Found %i digest recipients out of %i project members/groups." % [recipients.length, members.length]
		return recipients
	end
  
	def self.digests(options={})
		start_default = Setting.plugin_redmine_digest[:start_default].to_i
		days_default = Setting.plugin_redmine_digest[:days_default].to_i
		debugging_default = Setting.plugin_redmine_digest[:debugging_messages].to_i
		days = options[:days].nil? ? days_default : options[:days].to_i
		start = options[:start].nil? ? start_default : options[:start].to_i
		@debugging = options[:debugging_messages].nil? ? debugging_default : options[:debugging_messages].to_i
		dbg ""
		log "====="
		log "Start: %d" % start
		log "Days : %d" % days
		results = []
		projects = get_projects(options[:project])
		return results if projects.nil?
		projects.each do |project|
			dbg ""
			log "** Processing project '%s'..." % project.name
			
			body = {
				:project => project,
				:start => start,
				:days => days,
				:test_email => options[:test_email],
				:events => []
			}
			fill_events(project, body)
			if body[:events].empty?
			  message = "No events were found for project %s." % project.to_s
			  log message
			  results << message
			  next
			end
			dbg "Found %i events." % [body[:events].length]
			recipients = options[:test_email].nil? ? get_recipients(project) : options[:test_email]
			if recipients.empty?
				message = "No members were found for project %s." % project.to_s
				log message
				results << message
				next
			end
			if Rails::VERSION::MAJOR >= 3
				email = digest(project, recipients, body, start).deliver
			else
				email = deliver_digest(project, recipients, body, start)
			end
			if email.nil?
				message = "Email delivery failed for project '%s'" % project.name
			elsif not email.respond_to?('subject')
				if email.is_a? String
					message = email 
				else
					message = "The email does not have a subject, so it is assumed something went wrong."
				end
			else
				period = body[:date_from] == body[:date_to]-1 ? format_date(body[:date_from]) : l(:label_date_from_to, :start => format_date(body[:date_from]), :end => format_date(body[:date_to]-1)).downcase
				message = "Sent digest: %s (%s)" % [email.subject, period]
			end
			log message
			results << message
		end
		return results
	rescue Exception => e
		if Rails::VERSION::MAJOR >= 3
			logger.error e.message unless logger.nil?
		else
			logger.error e.message, e.backtrace unless logger.nil?
		end
	end
	
	def dbg(message)
		DigestMailer.dbg message
	end
	
	def self.dbg(message)
		if Setting.plugin_redmine_digest[:debugging_messages] || @debugging
			puts message
			logger.info(message) unless logger.nil?
		else	
			puts "debugging_messages: %s" % Setting.plugin_redmine_digest[:debugging_messages]
			logger.info("debugging_messages: %s" % Setting.plugin_redmine_digest[:debugging_messages]) unless logger.nil?
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
	
	def log(info_message)
		DigestMailer.log(info_message)
	end
	
	def self.log(info_message)
		if Setting.plugin_redmine_digest[:debugging_messages] || @debugging
			puts info_message
		end
		logger.info(info_message) unless logger.nil?
	end

end

