require "faraday"

module ExchangeRates
  class FetchRateService < ApplicationService
    API_URL = "https://open.er-api.com/v6/latest"

    def initialize(base_currency: "USD", target_currency: "EUR")
      @base_currency = base_currency.to_s.upcase
      @target_currency = target_currency.to_s.upcase
    end

    def call
      if @base_currency == @target_currency
        return success(exchange_rate: 1.0)
      end

      response = connection.get("/v6/latest/#{@base_currency}")

      if response.success?
        body = JSON.parse(response.body)
        rates = body.fetch("rates", {})
        rate = rates[@target_currency]

        if rate
          success(exchange_rate: rate.to_f)
        else
          failure("Target currency '#{@target_currency}' not found in exchange rate data")
        end
      else
        fallback_rate = fallback_rates[@target_currency] || 1.0
        success(exchange_rate: fallback_rate, note: "Rate retrieved from cached fallback due to API response status #{response.status}")
      end
    rescue Faraday::Error, JSON::ParserError => e
      fallback_rate = fallback_rates[@target_currency] || 1.0
      success(exchange_rate: fallback_rate, note: "Fallback used due to error: #{e.message}")
    end

    private

    def connection
      @connection ||= Faraday.new(url: API_URL) do |faraday|
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = 5
        faraday.options.open_timeout = 3
      end
    end

    def fallback_rates
      {
        "EUR" => 0.92,
        "GBP" => 0.78,
        "MXN" => 17.50,
        "COP" => 4150.00
      }
    end
  end
end
