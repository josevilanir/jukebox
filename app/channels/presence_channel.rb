class PresenceChannel < ActionCable::Channel::Base
  def subscribed
    @room = Room.find_by!(slug: params[:room_slug])
    stream_from "presence:#{@room.slug}"
    update_presence(true)
  end

  def unsubscribed
    update_presence(false) if @room
  end

  def heartbeat(_data)
    update_presence(true) if @room
  end

  def self.user_count(slug)
    set = Rails.cache.read("presence:#{slug}") || {}
    cutoff = 40.seconds.ago.to_i
    set.count { |_k, v| v[:at] >= cutoff }
  end

  private

  def update_presence(online)
    set_key = "presence:#{@room.slug}"
    set = Rails.cache.read(set_key) || {}

    if online
      set[current_user.id.to_s] = { name: current_user.name, at: Time.current.to_i }
    else
      set.delete(current_user.id.to_s)
    end

    # Limpa entradas antigas (mais de 40s sem heartbeat)
    cutoff = 40.seconds.ago.to_i
    set.reject! { |_k, v| v[:at] < cutoff }

    Rails.cache.write(set_key, set, expires_in: 1.hour)

    ActionCable.server.broadcast("presence:#{@room.slug}", { count: set.size })
  end
end
