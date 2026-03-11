Rack::Attack.cache.store = Rails.cache

# Limit YouTube searches: 15 per minute per IP
Rack::Attack.throttle("searches/ip", limit: 15, period: 60) do |req|
  req.ip if req.path.include?("/search") && req.get?
end

# Limit room creation: 5 per 5 minutes per IP
Rack::Attack.throttle("rooms/create/ip", limit: 5, period: 300) do |req|
  req.ip if req.path == "/rooms" && req.post?
end

# Return 429 with a plain message (Turbo handles non-2xx gracefully)
Rack::Attack.throttled_responder = lambda do |req|
  match_data = req.env["rack.attack.match_data"]
  retry_after = match_data ? (match_data[:period] - (Time.now.to_i % match_data[:period])) : 60

  [
    429,
    {
      "Content-Type" => "text/plain",
      "Retry-After" => retry_after.to_s
    },
    [ "Muitas requisições. Tente novamente em #{retry_after} segundos." ]
  ]
end
