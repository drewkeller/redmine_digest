require 'rake'
require 'redmine'
require 'rubygems'
require 'rufus/scheduler'
require 'action_mailer'

Redmine::Plugin.register :digest do
  name 'Digest plugin'
  author 'Drew Keller'
  description 'A plugin to send email digests of project activity. This plugin must be called by a scheduler (cronjob, Windows task, etc.).'
  version '0.0.1'

  settings :default => { :start_default => 1, :days_default => 1}, :partial => 'settings/digest_settings'

  project_module :digest do
    # we need a dummy permission to enable per-project module enablement
    permission :dummy, {:dummy => [:dummy]}, :public => true
  end
  version '0.0.1'
end
