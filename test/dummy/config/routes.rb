Rails.application.routes.draw do
  mount Schedulable::Engine => "/schedulable"
end
