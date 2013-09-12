class AddDigitsToInteraction < ActiveRecord::Migration
  def change
    add_column :interactions, :digits, :string
  end
end
