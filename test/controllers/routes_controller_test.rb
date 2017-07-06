require 'test_helper'

require 'rexml/document'
include REXML

class RoutesControllerTest < ActionController::TestCase

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @route = routes(:route_one_one)
    sign_in users(:user_one)
  end

  test 'user can only view routes from its customer' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :manage, @route
    ability = Ability.new(users(:user_three))
    assert ability.cannot? :manage, @route

    get :show, id: routes(:route_one_three)
    assert_response :redirect
  end

  test 'should show route' do
    get :show, id: @route
    assert_response :success
    assert_valid response
  end

  test 'should show route as csv' do
    get :show, id: @route, type: :csv
    assert_response :success
  end

  test 'should show route as excel' do
    get :show, id: @route, format: :excel
    assert_response :success
  end

  test 'should show route as gpx' do
    get :show, id: @route, format: :gpx
    assert_response :success
    assert Document.new(response.body)
  end

  test 'should show route as kml' do
    get :show, id: @route, format: :kml
    assert_response :success
    assert Document.new(response.body)
  end

  test 'should show route as kmz' do
    get :show, id: @route, format: :kmz
    assert_response :success
  end

  test 'should show route as kmz by email' do
    get :show, id: @route, format: :kmz, email: 1
    assert_response :success
  end

  test 'should update route' do
    patch :update, id: @route, route: { hidden: @route.hidden, locked: @route.locked, ref: 'ref8' }
    assert_redirected_to route_path(assigns(:route))
  end

  test 'should update route without loading stops' do
    begin
      Stop.class_eval do
        after_initialize :after_init

        def after_init
          raise
        end
      end

      patch :update, id: @route, route: { hidden: @route.hidden, locked: @route.locked, ref: 'ref8' }
      assert_response 302
    ensure
      Stop.class_eval do
        def after_init
        end
      end
    end
  end
end
