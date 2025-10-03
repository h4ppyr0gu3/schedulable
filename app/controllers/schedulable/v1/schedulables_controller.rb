module Schedulable
  module V1
    class SchedulablesController < ApplicationController
      skip_before_action :verify_authenticity_token

      def index
        association = find_association_by_params if association_params.present?
        day_of_week = params[:day_of_week]

        schedules = association.present? ? association.schedules : Schedulable::Schedule.all
        schedules = schedules.where(day_of_week: day_of_week) if day_of_week.present?

        @schedulables = schedules
        render json: @schedulables
      end

      def create
        @schedulable = Schedulable::Schedule.new(creation_params)
        if @schedulable.save
          render json: @schedulable, status: :created
        else
          render json: @schedulable.errors, status: :unprocessable_entity
        end
      end

      def update
        @schedulable = Schedulable::Schedule.find(params[:id])
        if @schedulable.update(creation_params)
          render json: @schedulable, status: :ok
        else
          render json: @schedulable.errors, status: :unprocessable_entity
        end
      end

      def bulk_replace
        schedulable = find_association_by_params if association_params.present?

        existing_schedules = schedulable.schedules

        ActiveRecord::Base.transaction do
          schedule_ids_to_delete = existing_schedules.map(&:id) - params[:schedules].map { |s| s[:id] }

          Schedulable::Schedule.where(id: schedule_ids_to_delete).destroy_all

          pp params[:schedules]

          schedules_to_create = params[:schedules].select { |s| s[:id].blank? }
          schedules_to_create.each do |s|
            creation_params = s.permit(:day_of_week, :starts_at, :ends_at)
              .merge(schedulable_id: schedulable.id,
                schedulable_type: schedulable.class.name)
            Schedulable::Schedule.create(creation_params)
          end

          schedules_to_update = params[:schedules].select { |s| s[:id].present? }
          schedules_to_update.each do |s|
            Schedulable::Schedule.find(s[:id]).update(s)
          end
        end

        render json: schedulable.schedules.order(:day_of_week)
      end

      def destroy
        @schedulable = Schedulable::Schedule.find(params[:id])
        @schedulable.destroy
        head :no_content
      end

      private

      def permitted_bulk_params
        params.permit(
          :schedulable_type,
          :schedulable_id,
          schedules:
          [ :day_of_week, :starts_at, :ends_at ]
        )
        # {
        #   "schedulable_type": "Camera",
        #   "schedulable_id": 7,
        #   "schedules": [
        #     { "id": 2, "day_of_week": 1, "starts_at": "00:00", "ends_at": "05:00" },
        #     { "id": 3, "day_of_week": 1, "starts_at": "09:00", "ends_at": "17:00" },
        #     { "day_of_week": 2, "starts_at": "13:00", "ends_at": "15:00" }
        #   ]
        # }
      end

      def association_params
        # Expect schedulable_* either at top-level or nested under :schedule
        if params[:schedulable_id].present? && params[:schedulable_type].present?
          return params.permit(:schedulable_id, :schedulable_type)
        elsif params[:schedule].is_a?(ActionController::Parameters)
          nested = params.require(:schedule)
          if nested[:schedulable_id].present? && nested[:schedulable_type].present?
            return nested.permit(:schedulable_id, :schedulable_type)
          end
        end
        nil
      end

      def find_association_by_params
        assoc = association_params
        return nil unless assoc
        type = assoc[:schedulable_type]
        id = assoc[:schedulable_id]
        type.constantize.find(id)
      rescue NameError
        raise ActiveRecord::RecordNotFound, "Invalid association type: #{type}"
      end

      def creation_params
        params.require(:schedule).permit(:day_of_week, :starts_at, :ends_at, :schedulable_id, :schedulable_type)
      end
    end
  end
end
