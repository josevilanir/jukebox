Rack::Attack.cache.store = Rails.cache

# Fly.io terminates TLS at the edge and injects the real client IP in Fly-Client-IP.
# Falling back to X-Forwarded-For (Thruster) and then Rack's default req.ip for local dev.
class Rack::Attack
  class Request < ::Rack::Request
    def client_ip
      env["HTTP_FLY_CLIENT_IP"] ||
        env["HTTP_X_FORWARDED_FOR"]&.split(",")&.first&.strip ||
        ip
    end
  end
end

# Limit YouTube searches: 15 per minute per IP
Rack::Attack.throttle("searches/ip", limit: 15, period: 60) do |req|
  req.client_ip if req.path.include?("/search") && req.get?
end

# Limit room creation: 5 per 5 minutes per IP
Rack::Attack.throttle("rooms/create/ip", limit: 5, period: 300) do |req|
  req.client_ip if req.path == "/rooms" && req.post?
end

# Limit votes (upvotes): 30 per minute per IP
Rack::Attack.throttle("votes/ip", limit: 30, period: 60) do |req|
  req.client_ip if req.path.end_with?("/votes") && req.post?
end

# Limit skip votes: 10 per minute per IP
Rack::Attack.throttle("skip_votes/ip", limit: 10, period: 60) do |req|
  req.client_ip if req.path.end_with?("/skip_votes") && req.post?
end

# Limit chat messages: 20 per minute per IP
Rack::Attack.throttle("messages/ip", limit: 20, period: 60) do |req|
  req.client_ip if req.path.end_with?("/messages") && req.post?
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
