defmodule Moov.CaseConverterTest do
  use ExUnit.Case, async: true

  alias Moov.CaseConverter

  describe "to_camel_case/1" do
    test "converts top-level snake_case atom keys to camelCase strings" do
      assert CaseConverter.to_camel_case(%{legal_business_name: "Acme"}) == %{
               "legalBusinessName" => "Acme"
             }
    end

    test "converts snake_case string keys to camelCase strings" do
      assert CaseConverter.to_camel_case(%{"legal_business_name" => "Acme"}) == %{
               "legalBusinessName" => "Acme"
             }
    end

    test "leaves already-camelCase keys untouched" do
      assert CaseConverter.to_camel_case(%{accountID: "abc"}) == %{"accountID" => "abc"}
    end

    test "recurses into nested maps" do
      input = %{address: %{postal_code: "80301", state_or_province: "CO"}}

      assert CaseConverter.to_camel_case(input) == %{
               "address" => %{"postalCode" => "80301", "stateOrProvince" => "CO"}
             }
    end

    test "recurses into lists of maps" do
      input = %{line_items: [%{unit_price: 100}, %{unit_price: 200}]}

      assert CaseConverter.to_camel_case(input) == %{
               "lineItems" => [%{"unitPrice" => 100}, %{"unitPrice" => 200}]
             }
    end

    test "passes struct values through untouched (so Jason can encode them with its own protocol)" do
      now = DateTime.utc_now()
      assert CaseConverter.to_camel_case(%{created_on: now}) == %{"createdOn" => now}
    end

    test "leaves non-map, non-list, non-struct leaves untouched" do
      assert CaseConverter.to_camel_case(%{count: 5, active: true, note: nil}) == %{
               "count" => 5,
               "active" => true,
               "note" => nil
             }
    end

    test "single-word keys are unaffected" do
      assert CaseConverter.to_camel_case(%{name: "Ada"}) == %{"name" => "Ada"}
    end
  end

  describe "to_snake_case/1" do
    test "converts camelCase string keys to snake_case strings" do
      assert CaseConverter.to_snake_case(%{"accountID" => "abc", "displayName" => "Ada"}) == %{
               "account_id" => "abc",
               "display_name" => "Ada"
             }
    end

    test "recurses into nested maps and lists" do
      input = %{"walletTransactions" => [%{"transactionID" => "t1"}]}

      assert CaseConverter.to_snake_case(input) == %{
               "wallet_transactions" => [%{"transaction_id" => "t1"}]
             }
    end

    test "never produces atom keys (safe against atom-table exhaustion from untrusted responses)" do
      result = CaseConverter.to_snake_case(%{"someBrandNewFieldMoovAddedYesterday" => 1})
      assert Map.keys(result) == ["some_brand_new_field_moov_added_yesterday"]
      assert is_binary(hd(Map.keys(result)))
    end

    test "passes struct values through untouched" do
      now = DateTime.utc_now()
      assert CaseConverter.to_snake_case(%{"createdOn" => now}) == %{"created_on" => now}
    end
  end
end
