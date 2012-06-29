
require_dependency 'project'
require_dependency 'principal'
require_dependency 'user'

# Guards against including the module multiple times (like in tests)
# and registering multiple callbacks
unless User.included_modules.include? RedmineDigest::UserPatch
	User.send(:include, RedmineDigest::UserPatch)
end
