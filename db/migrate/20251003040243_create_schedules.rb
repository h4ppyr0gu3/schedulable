class CreateSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :schedules do |t|
      t.integer :day_of_week
      t.time :starts_at
      t.time :ends_at
      t.references :schedulable, polymorphic: true

      t.timestamps
    end
  end
end
