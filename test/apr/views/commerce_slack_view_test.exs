defmodule Apr.Views.CommerceSlackViewTest do
  use ExUnit.Case, async: true
  alias Apr.Views.CommerceSlackView
  alias Apr.Fixtures
  import Mox

  setup do
    expect(Apr.PaymentsMock, :payment_info, fn _, _ ->
      {:ok, %{liability_shift: true, card_country: "XY", zip_check: true, cvc_check: true}}
    end)

    :ok
  end

  test "Transaction event renders transaction message" do
    event =
      Apr.Fixtures.commerce_transaction_event(%{
        "id" => "order123",
        "items_total_cents" => 2_000_000,
        "currency_code" => "USD"
      })

    slack_view = CommerceSlackView.render(event, "transaction.failure")

    assert slack_view.text ==
             ":alert: <https://dashboard.stripe.com/search?query=order123|insufficient_funds>"
  end

  test "Offer event renders offer message" do
    event = Apr.Fixtures.commerce_offer_event("submitted", %{"amount_cents" => 300})
    slack_view = CommerceSlackView.render(event, "offer.submitted")
    assert slack_view.text == ":parrotsunnies: Counteroffer submitted"
  end

  test "Order event renders order message" do
    event = Fixtures.commerce_order_event()
    slack_view = CommerceSlackView.render(event, "order.submitted")
    assert slack_view.text == "🤞 Submitted  :verified: <https://www.artsy.net/artwork/artwork1| >"
    assert slack_view[:unfurl_links] == true
  end

  test "Error event renders error message" do
    event = Apr.Fixtures.commerce_error_event()
    slack_view = CommerceSlackView.render(event, "error.validation.insufficient_funds")
    assert slack_view.text == ":alert: Failed submitting an order"
  end
end
