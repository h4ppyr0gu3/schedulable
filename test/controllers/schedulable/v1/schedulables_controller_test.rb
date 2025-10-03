require "test_helper"

class Schedulable::V1::SchedulablesControllerTest < ActionController::TestCase
  tests Schedulable::V1::SchedulablesController

  def t(h, m = 0)
    Time.zone.parse(format("%02d:%02d", h, m))
  end

  def setup
    @routes = Schedulable::Engine.routes
    @camera1 = Camera.create!(name: "Cam 1")
    @camera2 = Camera.create!(name: "Cam 2")

    @s1 = Schedulable::Schedule.create!(schedulable: @camera1, day_of_week: 1, starts_at: t(9, 0), ends_at: t(10, 0))
    @s2 = Schedulable::Schedule.create!(schedulable: @camera1, day_of_week: 2, starts_at: t(11, 0), ends_at: t(12, 0))
    @s3 = Schedulable::Schedule.create!(schedulable: @camera2, day_of_week: 1, starts_at: t(13, 0), ends_at: t(14, 0))
  end

  test "index without filters returns all schedules" do
    get :index, as: :json
    body = JSON.parse(@response.body)
    assert_equal [ @s1, @s2, @s3 ].map(&:id).sort, body.map { |h| h["id"] }.sort
  end

  test "index filtered by association returns only that association's schedules" do
    get :index, params: { schedulable_type: "Camera", schedulable_id: @camera1.id }, as: :json
    body = JSON.parse(@response.body)
    assert_equal [ @s1, @s2 ].map(&:id).sort, body.map { |h| h["id"] }.sort
  end

  test "index filtered by day_of_week returns only schedules for that day" do
    get :index, params: { day_of_week: 1 }, as: :json
    body = JSON.parse(@response.body)
    assert_equal [ @s1, @s3 ].map(&:id).sort, body.map { |h| h["id"] }.sort
  end

  test "index filtered by association and day_of_week narrows correctly" do
    get :index, params: { schedulable_type: "Camera", schedulable_id: @camera1.id, day_of_week: 2 }, as: :json
    body = JSON.parse(@response.body)
    assert_equal [ @s2.id ], body.map { |h| h["id"] }
  end

  test "create with valid params creates schedule and returns JSON 201" do
    assert_difference -> { Schedulable::Schedule.count }, +1 do
      post :create, params: {
        schedule: {
          schedulable_type: "Camera",
          schedulable_id: @camera1.id,
          day_of_week: 3,
          starts_at: t(15, 0),
          ends_at: t(16, 0)
        }
      }, as: :json
    end

    assert_response :created
    body = JSON.parse(@response.body)
    assert_equal @camera1.id, body["schedulable_id"]
    assert_equal "Camera", body["schedulable_type"]
    assert_equal 3, body["day_of_week"]
  end

  test "create with invalid timings returns 422 and errors JSON" do
    assert_no_difference -> { Schedulable::Schedule.count } do
      post :create, params: {
        schedule: {
          schedulable_type: "Camera",
          schedulable_id: @camera1.id,
          day_of_week: 1,
          starts_at: t(18, 0),
          ends_at: t(17, 0)
        }
      }, as: :json
    end

    assert_response :unprocessable_entity
    errors = JSON.parse(@response.body)
    assert_includes errors["ends_at"], "must be after starts_at"
  end

  test "update with valid params updates and returns JSON 200" do
    schedule = Schedulable::Schedule.create!(schedulable: @camera1, day_of_week: 0, starts_at: t(7, 0), ends_at: t(8, 0))

    patch :update, params: {
      id: schedule.id,
      schedule: {
        day_of_week: 6,
        starts_at: t(9, 30),
        ends_at: t(10, 30)
      }
    }, as: :json

    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal 6, body["day_of_week"]
  end

  test "update with invalid timings returns 422 and errors JSON" do
    schedule = Schedulable::Schedule.create!(schedulable: @camera1, day_of_week: 0, starts_at: t(7, 0), ends_at: t(8, 0))

    patch :update, params: {
      id: schedule.id,
      schedule: {
        starts_at: t(12, 0),
        ends_at: t(11, 0)
      }
    }, as: :json

    assert_response :unprocessable_entity
    errors = JSON.parse(@response.body)
    assert_includes errors["ends_at"], "must be after starts_at"
  end

  test "destroy removes schedule and returns 204" do
    schedule = Schedulable::Schedule.create!(schedulable: @camera1, day_of_week: 2, starts_at: t(6, 0), ends_at: t(7, 0))

    assert_difference -> { Schedulable::Schedule.where(id: schedule.id).count }, -1 do
      delete :destroy, params: { id: schedule.id }, as: :json
    end

    assert_response :no_content
  end
end
