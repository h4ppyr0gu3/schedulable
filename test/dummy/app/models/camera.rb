class Camera < ApplicationRecord
    has_many :schedules, as: :schedulable, class_name: "Schedulable::Schedule", dependent: :destroy
end
