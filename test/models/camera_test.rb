require "test_helper"

class CameraTest < ActiveSupport::TestCase
  def setup
    @camera = Camera.create!(name: "Cam Assoc")
  end

  def t(h, m = 0)
    Time.zone.parse(format("%02d:%02d", h, m))
  end

  test "has many schedules via polymorphic association" do
    s1 = Schedulable::Schedule.create!(schedulable: @camera, day_of_week: 1, starts_at: t(9, 0), ends_at: t(10, 0))
    s2 = Schedulable::Schedule.create!(schedulable: @camera, day_of_week: 2, starts_at: t(11, 0), ends_at: t(12, 0))

    ids = @camera.schedules.pluck(:id)
    assert_includes ids, s1.id
    assert_includes ids, s2.id
    assert_equal 2, @camera.schedules.count
  end

  test "schedule.schedulable returns the camera" do
    schedule = Schedulable::Schedule.create!(schedulable: @camera, day_of_week: 3, starts_at: t(8, 0), ends_at: t(9, 0))
    assert_equal @camera, schedule.schedulable
  end

  test "destroying camera removes its schedules (dependent destroy)" do
    s1 = Schedulable::Schedule.create!(schedulable: @camera, day_of_week: 1, starts_at: t(9, 0), ends_at: t(10, 0))
    s2 = Schedulable::Schedule.create!(schedulable: @camera, day_of_week: 2, starts_at: t(11, 0), ends_at: t(12, 0))

    assert_difference -> { Schedulable::Schedule.where(id: [ s1.id, s2.id ]).count }, -2 do
      @camera.destroy
    end
  end
end
