require 'test_helper'

class TrajectoryOptimizationControllerTest < ActionController::TestCase
  test "should get init" do
    get :init
    assert_response :success
  end

  test "should get continue" do
    get :continue
    assert_response :success
  end

end
