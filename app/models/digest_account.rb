# nothing here really, but having it prevents 'uninitialized constant: User::DigestAccount'
class DigestAccount < ActiveRecord::Base
  unloadable
  belongs_to :user

end
