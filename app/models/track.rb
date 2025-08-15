class Track < ApplicationRecord
  has_many :queue_items, dependent: :restrict_with_exception

  validates :title, :source, :external_id, presence: true

  def youtube_id
    return external_id if source == "youtube"
  end

  # Cria/obtém Track a partir de uma URL do YouTube (sem API por enquanto)
  def self.from_youtube_url(url)
    vid = extract_youtube_id(url)
    raise ArgumentError, "URL do YouTube inválida" if vid.blank?

    find_or_create_by!(source: "youtube", external_id: vid) do |t|
      t.title = "YouTube ##{vid}"
      t.thumbnail_url = "https://img.youtube.com/vi/#{vid}/hqdefault.jpg"
      t.duration = nil
      t.artist = nil
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
end
