module RedmineDigest
  # Patches Redmine's Users dynamically.  Adds a relation to digest_account.
  module UserPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      # Same as typing in the class 
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        has_one :digest_account
        accepts_nested_attributes_for :digest_account
        safe_attributes 'digest_account'
        safe_attributes 'digest_account_attributes'
      end

    end

    module ClassMethods
    end

    module InstanceMethods
    end
  end
end

