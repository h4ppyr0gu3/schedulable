require "test_helper"

class ScheduleTest < ActiveSupport::TestCase
  def setup
    @camera = Camera.create!(name: "Cam 1")
  end

  def t(h, m = 0)
    Time.zone.parse(format("%02d:%02d", h, m))
  end

  test "is valid with valid attributes" do
    schedule = Schedulable::Schedule.new(
      schedulable: @camera,
      day_of_week: 1,
      starts_at: t(9, 0),
      ends_at: t(17, 0)
    )

    assert schedule.valid?
  end

  test "is invalid when ends_at is before starts_at" do
    schedule = Schedulable::Schedule.new(
      schedulable: @camera,
      day_of_week: 1,
      starts_at: t(18, 0),
      ends_at: t(17, 0)
    )

    assert_not schedule.valid?
    assert_includes schedule.errors[:ends_at], "must be after starts_at"
  end

  class OverlapChecks < ActiveSupport::TestCase
    def setup
      @camera = Camera.create!(name: "Cam 1")
      @existing = Schedulable::Schedule.create!(
        schedulable: @camera,
        day_of_week: 2,
        starts_at: t(9, 0),
        ends_at: t(11, 0)
      )
    end

    def t(h, m = 0)
      Time.zone.parse(format("%02d:%02d", h, m))
    end

    test "rejects a schedule that starts inside an existing schedule" do
      s = Schedulable::Schedule.new(schedulable: @camera, day_of_week: 2, starts_at: t(10, 0), ends_at: t(12, 0))
      assert_not s.valid?
      assert_includes s.errors[:schedule], "There are overlapping schedules"
    end

    test "rejects a schedule that ends inside an existing schedule" do
      s = Schedulable::Schedule.new(schedulable: @camera, day_of_week: 2, starts_at: t(8, 0), ends_at: t(10, 30))
      assert_not s.valid?
      assert_includes s.errors[:schedule], "There are overlapping schedules"
    end

    test "rejects a schedule that fully wraps an existing schedule" do
      s = Schedulable::Schedule.new(schedulable: @camera, day_of_week: 2, starts_at: t(8, 0), ends_at: t(12, 0))
      assert_not s.valid?
      assert_includes s.errors[:schedule], "There are overlapping schedules"
    end

    test "allows a schedule that does not overlap (ends before)" do
      s = Schedulable::Schedule.new(schedulable: @camera, day_of_week: 2, starts_at: t(7, 0), ends_at: t(9, 0))
      assert s.valid?
    end

    test "allows a schedule that does not overlap (starts after)" do
      s = Schedulable::Schedule.new(schedulable: @camera, day_of_week: 2, starts_at: t(11, 0), ends_at: t(12, 0))
      assert s.valid?
    end

    test "allows two non-overlapping schedules on same day (08-12 and 13-15)" do
      Schedulable::Schedule.create!(
        schedulable: @camera,
        day_of_week: 3,
        starts_at: t(8, 0),
        ends_at: t(12, 0)
      )

      afternoon = Schedulable::Schedule.new(
        schedulable: @camera,
        day_of_week: 3,
        starts_at: t(13, 0),
        ends_at: t(15, 0)
      )

      assert afternoon.valid?
    end

    test "allows two non-overlapping schedules regardless of creation order (13-15 then 08-12)" do
      Schedulable::Schedule.create!(
        schedulable: @camera,
        day_of_week: 4,
        starts_at: t(13, 0),
        ends_at: t(15, 0)
      )

      morning = Schedulable::Schedule.new(
        schedulable: @camera,
        day_of_week: 4,
        starts_at: t(8, 0),
        ends_at: t(12, 0)
      )

      assert morning.valid?
    end

    test "is invalid when an existing 08-12 overlaps a new 10-14 on the same day" do
      Schedulable::Schedule.create!(
        schedulable: @camera,
        day_of_week: 5,
        starts_at: t(8, 0),
        ends_at: t(12, 0)
      )

      overlapping = Schedulable::Schedule.new(
        schedulable: @camera,
        day_of_week: 5,
        starts_at: t(10, 0),
        ends_at: t(14, 0)
      )

      assert_not overlapping.valid?
      assert_includes overlapping.errors[:schedule], "There are overlapping schedules"
    end

    test "allows same time range on different day_of_week" do
      s = Schedulable::Schedule.new(schedulable: @camera, day_of_week: 3, starts_at: t(9, 0), ends_at: t(11, 0))
      assert s.valid?
    end

    test "allows same time range for a different schedulable on same day_of_week" do
      other_camera = Camera.create!(name: "Cam 2")
      s = Schedulable::Schedule.new(schedulable: other_camera, day_of_week: 2, starts_at: t(9, 0), ends_at: t(11, 0))
      assert s.valid?
    end
  end

  test "associations - can belong to a polymorphic schedulable (Camera)" do
    schedule = Schedulable::Schedule.create!(schedulable: @camera, day_of_week: 1, starts_at: t(9, 0), ends_at: t(10, 0))
    assert_equal @camera, schedule.schedulable
  end
end
