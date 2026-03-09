require "net/http"
require "json"
require "uri"

class Track < ApplicationRecord
  has_many :queue_items, dependent: :restrict_with_exception

  validates :title, :source, :external_id, presence: true

  def youtube_id
    external_id if source == "youtube"
  end

  # Cria/obtém Track a partir de uma URL do YouTube (usa oEmbed, sem API key)
  def self.from_youtube_url(url)
    vid = extract_youtube_id(url)
    raise ArgumentError, "URL do YouTube inválida" if vid.blank?

    find_or_create_by!(source: "youtube", external_id: vid) do |t|
      meta = fetch_youtube_oembed(vid)
      t.title         = meta[:title] || "YouTube ##{vid}"
      t.thumbnail_url = meta[:thumbnail_url] || "https://img.youtube.com/vi/#{vid}/hqdefault.jpg"
      t.duration      = nil
      t.artist        = nil
    end
  end

  def self.extract_youtube_id(url)
    return nil if url.blank?
    uri = URI.parse(url) rescue nil
    return nil unless uri

    if uri.host&.include?("youtu.be")
      uri.path.split("/").last
    elsif uri.host&.include?("youtube.com")
      Rack::Utils.parse_query(uri.query).fetch("v", nil)
    end
  end

  # ---- helpers privados

  def self.fetch_youtube_oembed(vid)
    oembed_url = URI.parse("https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=#{vid}&format=json")
    res = Net::HTTP.start(oembed_url.host, oembed_url.port, use_ssl: true) do |http|
      http.read_timeout = 4
      http.open_timeout = 3
      http.get(oembed_url.request_uri)
    end
    if res.is_a?(Net::HTTPSuccess)
      data = JSON.parse(res.body)
      {
        title: data["title"],
        thumbnail_url: data["thumbnail_url"]
      }
    else
      {}
    end
  rescue => _e
    {}
  end

  private_class_method :fetch_youtube_oembed
end
