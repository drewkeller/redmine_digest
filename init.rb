require 'rake'
require 'redmine'
require 'rubygems'
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3
require 'action_mailer'


require_dependency 'project'
require_dependency 'principal'
require_dependency 'user'

require_dependency 'redmine_digest/hooks/view_my_account_hook'
#require 'redmine_digest/user_patch'

if Rails::VERSION::MAJOR >= 3
  Rails.configuration.to_prepare do
    require_dependency 'redmine_digest_patches'
  end
else
  Dispatcher.to_prepare :redmine_digest do
    require_dependency 'redmine_digest_patches'
  end
end

Redmine::Plugin.register :redmine_digest do
  name 'Digest plugin'
  author 'Drew Keller'
  #author_url
  url 'http://github.com/drewkeller/redmine_digest.git' if respond_to?(:url)
  description 'A plugin to send email digests of project activity. This plugin must be called by a scheduler (cronjob, Windows task, rufus-scheduler, etc.). NOTE to upgraders from 0.0.1: You MUST perform db:migrate_plugins after upgrading!!!'
  version '0.2.0'
  requires_redmine :version_or_higher => '2.0.0' unless Rails::VERSION::MAJOR < 3

  settings :default => { 
	:start_default => 1, 
	:days_default => 1,
	:default_account_enabled => "true",
	:debugging_messages => 1}, 
	:partial => 'settings/digest_settings'

  project_module :redmine_digest do
    # we need a dummy permission to enable per-project module enablement
    permission :dummy, {:dummy => [:dummy]}, :public => true
  end

end
