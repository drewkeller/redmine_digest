require 'rake'
require 'redmine'
require 'rubygems'
require 'action_mailer'

Redmine::Plugin.register :digest do
  name 'Digest plugin'
  author 'Drew Keller'
  #author_url
  url 'http://github.com/drewkeller/redmine_digest.git' if respond_to?(:url)
  description 'A plugin to send email digests of project activity. This plugin must be called by a scheduler (cronjob, Windows task, rufus-scheduler, etc.).'
  version '0.0.1'

  settings :default => { :start_default => 1, :days_default => 1}, :partial => 'settings/digest_settings'

  project_module :digest do
    # we need a dummy permission to enable per-project module enablement
    permission :dummy, {:dummy => [:dummy]}, :public => true
  end
  version '0.0.1'
end
