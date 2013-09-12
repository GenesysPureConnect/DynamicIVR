class CreateInteractionAttributes < ActiveRecord::Migration
  def change
    create_table :interaction_attributes do |t|
      t.string :key
      t.string :value

      t.timestamps
      t.belongs_to :interaction
    end
  end
end
