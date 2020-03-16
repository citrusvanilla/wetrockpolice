# frozen_string_literal: true

require 'test_helper'
require 'json'

class MembershipsControllerTest < ActionDispatch::IntegrationTest
  include SnccApplication

  VALID_ORDER_ID = '1234FFF'
  INVALID_ORDER_ID = 'FFF321'

  setup do
    stub_request(
      :post,
      'https://api.sandbox.paypal.com/v1/oauth2/token'
    ).to_return(
      status: 200,
      body: { access_token: 'abcd' }.to_json,
      headers: { content_type: 'application/json' }
    )

    stub_request(
      :get,
      "https://api.sandbox.paypal.com/v2/checkout/orders/#{VALID_ORDER_ID}"
    )

    stub_request(
      :get,
      "https://api.sandbox.paypal.com/v2/checkout/orders/#{INVALID_ORDER_ID}"
    ).to_return(
      status: 404,
      body: { name: 'RESOURCE_NOT_FOUND' }.to_json,
      headers: { content_type: 'application/json' }
    )
  end

  test 'Accepts card payment' do
    submit_sncc_application(joint_membership_applications(:valid_application))

    assert_response :created
  end

  test 'Rejects invalid card payment' do
    app = joint_membership_applications(:valid_application)
    app.order_id = INVALID_ORDER_ID

    submit_sncc_application(app)

    assert_response :payment_required
  end

  test 'Accepts cash payment' do
    app = joint_membership_applications(:valid_application)
    app.order_id = nil
    app.paid_cash = true

    submit_sncc_application(app)

    assert_response :created
  end

  test 'Rejects empty order_id' do
    app = joint_membership_applications(:valid_application)
    app.order_id = nil
    app.paid_cash = false

    submit_sncc_application(app)

    assert_response :payment_required
  end

  test 'Fails validation' do
    app = joint_membership_applications(:valid_application)
    app.first_name = nil

    submit_sncc_application(app)

    assert_response :bad_request
  end
end