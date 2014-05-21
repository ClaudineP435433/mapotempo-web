# Copyright © Mapotempo, 2013-2014
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
require 'matrix_job'

class PlanningsController < ApplicationController
  load_and_authorize_resource :except => :create
  before_action :set_planning, only: [:show, :edit, :update, :destroy, :move, :refresh, :switch, :update_stop, :optimize_route]

  # GET /plannings
  # GET /plannings.json
  def index
    @plannings = Planning.where(customer_id: current_user.customer.id)
  end

  # GET /plannings/1
  # GET /plannings/1.json
  def show
    respond_to do |format|
      format.html
      format.json
      format.gpx do
        response.headers['Content-Disposition'] = 'attachment; filename="'+@planning.name.gsub('"', '')+'.gpx"'
      end
      format.excel do
        data = render_to_string
        send_data data.encode('ISO-8859-1'),
            type: 'text/csv',
            filename: @planning.name.gsub('"','')+'.csv'
      end
      format.csv do
        response.headers['Content-Disposition'] = 'attachment; filename="'+@planning.name.gsub('"', '')+'.csv"'
      end
    end
  end

  # GET /plannings/new
  def new
    @planning = Planning.new
  end

  # GET /plannings/1/edit
  def edit
  end

  # POST /plannings
  # POST /plannings.json
  def create
    respond_to do |format|
      begin
        Planning.transaction do
          @planning = Planning.new(planning_params)
          @planning.customer = current_user.customer
          @planning.default_routes
          @planning.save!
        end

        format.html { redirect_to edit_planning_path(@planning), notice: t('activerecord.successful.messages.created', model: @planning.class.model_name.human) }
        format.json { head :no_content }
      rescue
        format.html { render action: 'new' }
        format.json { render json: @planning.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /plannings/1
  # PATCH/PUT /plannings/1.json
  def update
    respond_to do |format|
      if @planning.update(planning_params)
        format.html { redirect_to edit_planning_path(@planning), notice: t('activerecord.successful.messages.updated', model: @planning.class.model_name.human) }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @planning.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /plannings/1
  # DELETE /plannings/1.json
  def destroy
    @planning.destroy
    respond_to do |format|
      format.html { redirect_to plannings_url }
      format.json { head :no_content }
    end
  end

  def move
    respond_to do |format|
      begin
        destinations = Hash[current_user.customer.destinations.map{ |d| [d.id, d] }]
        destinations[current_user.customer.store_id] = current_user.customer.store
        routes = Hash[@planning.routes.map{ |route| [String(route.id), route] }]
        Planning.transaction do
          params["_json"].each{ |r|
            route = routes[r[:route]]
            if r[:destinations]
              route.set_destinations(r[:destinations].collect{ |d| [destinations[d[:id]], !!d[:active]] })
            else
              route.set_destinations([])
            end
          }

          if @planning.save
            format.json { render action: 'show', location: @planning }
          else
            format.json { render json: @planning.errors, status: :unprocessable_entity }
          end
        end
      rescue StandardError => e
        format.json { render json: e.message, status: :unprocessable_entity }
      end
    end
  end

  def refresh
    respond_to do |format|
      begin
        @planning.compute
        if @planning.save
          format.json { render action: 'show', location: @planning }
        else
          format.json { render json: @planning.errors, status: :unprocessable_entity }
        end
      rescue StandardError => e
        format.json { render json: e.message, status: :unprocessable_entity }
      end
    end
  end

  def switch
    respond_to do |format|
      begin
        route = @planning.routes.find{ |route| route.id == Integer(params["route_id"]) }
        vehicle = Vehicle.where(id: Integer(params["vehicle_id"]), customer: current_user.customer).first
        if route and vehicle and @planning.switch(route, vehicle) and @planning.compute and @planning.save
          format.html { redirect_to @planning, notice: t('activerecord.successful.messages.updated', model: @planning.class.model_name.human) }
          format.json { render action: 'show', location: @planning }
        else
          format.json { render json: @planning.errors, status: :unprocessable_entity }
        end
      rescue StandardError => e
        format.json { render json: e.message, status: :unprocessable_entity }
      end
    end
  end

  def update_stop
    respond_to do |format|
      begin
        @route = Route.where(planning: @planning, id: params[:route_id]).first
        if @route
          @stop = Stop.where(route: @route, destination_id: params[:destination_id]).first
          if @stop
            if @stop.update(stop_params)
              @planning.compute
              @planning.save
              format.json { render action: 'show', location: @planning }
            else
              format.json { render json: @stop.errors, status: :unprocessable_entity }
            end
          end
        end
      rescue StandardError => e
        format.json { render json: e.message, status: :unprocessable_entity }
      end
    end
  end

  def optimize_route
    @route = Route.where(planning: @planning, id: params[:route_id]).first
    if @route
      respond_to do |format|
        if @route.stops.size <= 2 or (Optimizer::optimize(current_user.customer, @planning, @route) && current_user.save)
          format.html { redirect_to @planning, notice: t('activerecord.successful.messages.updated', model: @planning.class.model_name.human) }
          format.json { render action: 'show', location: @planning }
        else
          format.json { render json: @planning.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_planning
      @planning = Planning.find(params[:id] || params[:planning_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def planning_params
      params.require(:planning).permit(:name, :zoning_id, :tag_ids => [])
    end

    def stop_params
      params.require(:stop).permit(:active)
    end
end
