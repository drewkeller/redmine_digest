class CreateDigestAccounts < ActiveRecord::Migration
  def self.up
    create_table :digest_accounts, :force => true do |t|
      t.boolean :active
      t.integer :user_id
    end
  end

  def self.down
    drop_table :digest_accounts
  end
end
