class CreateInteractions < ActiveRecord::Migration
  def change
    create_table :interactions do |t|
      t.string :interactionid

      t.timestamps
    end
  end
end
