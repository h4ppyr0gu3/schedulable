module Schedulable
  class Schedule < ApplicationRecord
    # Ensure we use the existing table created by the engine migration
    self.table_name = "schedules"

    # day of week is .wday() from active support
    belongs_to :schedulable, polymorphic: true

    validate :schedule_is_valid
    validate :timings
    validates :starts_at, presence: true
    validates :ends_at, presence: true
    validates :day_of_week, inclusion: { in: 0..6 }, allow_nil: false

    def timings
      return if starts_at.blank? || ends_at.blank?

      errors.add(:ends_at, "must be after starts_at") if ends_at <= starts_at
    end

    def schedule_is_valid
      return if starts_at.blank? || ends_at.blank?

      scoped = Schedulable::Schedule.where(
        schedulable_id: schedulable_id,
        schedulable_type: schedulable_type,
        day_of_week: day_of_week
      )
      # Exclude self when updating
      scoped = scoped.where.not(id: id) if persisted?

      overlap_exists = scoped.any? do |existing|
        starts_at < existing.ends_at && ends_at > existing.starts_at
      end

      if overlap_exists
        errors.add(:schedule, "There are overlapping schedules")
      end
    end
  end
end
