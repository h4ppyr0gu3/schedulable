class CreateCameras < ActiveRecord::Migration[8.0]
  def change
    create_table :cameras do |t|
      t.string :name
      t.timestamps
    end
  end
end
