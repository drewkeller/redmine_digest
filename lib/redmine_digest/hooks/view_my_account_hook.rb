module RedmineDigest
  module Hooks
    class ViewMyAccountHook < Redmine::Hook::ViewListener
      render_on(:view_my_account, :partial => 'account_settings/settings', :layout => false)
      render_on(:view_users_form, :partial => 'account_settings/settings', :layout => false)
    end
  end
end
