# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

if Rails::VERSION::MAJOR >= 3
	match 'settings/plugin/redmine_digest/send_test_email', :to => 'digest#test_email', :via => 'get'
	match 'settings/plugin/redmine_digest/send_all', :to => 'digest#send_all', :via => 'get'
	match 'settings/plugin/redmine_digest/show_readme', :to => 'digest#show_readme', :via => 'get'
	
	resources 'digest'
else
	ActionController::Routing::Routes.draw do |map|
		map.connect 'settings/plugin/redmine_digest/test_email', :controller => 'digest', :action => 'test_email'
		map.connect 'settings/plugin/redmine_digest/send_all', :controller => 'digest', :action => 'send_all'
		map.connect 'settings/plugin/redmine_digest/show_readme', :controller => 'digest', :action => 'show_readme'
		map.resources :digest
	end
end
