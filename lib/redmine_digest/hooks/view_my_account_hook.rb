module RedmineDigest
	module Hooks
		class ViewMyAccountHook < Redmine::Hook::ViewListener
			if Rails::VERSION::MAJOR >= 3
				render_on(:view_my_account, :partial => 'account_settings/settings_2x', :layout => false)
				render_on(:view_users_form, :partial => 'account_settings/settings_2x', :layout => false)
			else
				render_on(:view_my_account, :partial => 'account_settings/settings_1x', :layout => false)
				render_on(:view_users_form, :partial => 'account_settings/settings_1x', :layout => false)
			end
		end
	end
end
