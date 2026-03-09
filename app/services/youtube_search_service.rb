# app/services/youtube_search_service.rb
require "net/http"
require "json"
require "uri"
require "cgi"

class YoutubeSearchService
  def self.embeddable?(video_id)
    # YouTube's oEmbed endpoint returns 401 for non-embeddable videos (error 101/150),
    # 404 for deleted/private, and 200 for videos that can be embedded.
    # No API key required, and it's more reliable than scraping ytInitialPlayerResponse.
    uri = URI("https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=#{CGI.escape(video_id)}&format=json")

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.open_timeout = 3
      http.read_timeout = 5
      http.request(Net::HTTP::Get.new(uri))
    end

    res.is_a?(Net::HTTPSuccess)
  rescue StandardError
    true # fail open on network error
  end

  def self.search(query)
    return [] if query.blank?

    uri = URI("https://www.youtube.com/results?search_query=#{CGI.escape(query)}")

    req = Net::HTTP::Get.new(uri)
    req["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    req["Accept-Language"] = "pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.read_timeout = 5
      http.open_timeout = 3
      http.request(req)
    end

    return [] unless res.is_a?(Net::HTTPSuccess)

    # Extrai a variável local onde o frontend do YouTube joga o state inicial da store Redux/Polymer
    match = res.body.match(/var ytInitialData = (\{.*?\});<\/script>/)
    return [] unless match

    begin
      data = JSON.parse(match[1])

      contents = data.dig("contents", "twoColumnSearchResultsRenderer", "primaryContents", "sectionListRenderer", "contents", 0, "itemSectionRenderer", "contents")
      return [] unless contents.is_a?(Array)

      results = []
      contents.each do |item|
        video = item["videoRenderer"]
        next unless video

        # Somente pegamos vídeos que têm duração, ignorando canais, playlists ou shorts estranhos
        next unless video["lengthText"]

        results << {
          id: video["videoId"],
          title: video.dig("title", "runs", 0, "text"),
          thumbnail_url: video.dig("thumbnail", "thumbnails", 0, "url"),
          duration: video.dig("lengthText", "simpleText"),
          channel: video.dig("longBylineText", "runs", 0, "text") || video.dig("ownerText", "runs", 0, "text")
        }

        break if results.size >= 8
      end

      results
    rescue JSON::ParserError, StandardError => e
      Rails.logger.error "[YoutubeSearchService] Error parsing youtube: #{e.message}"
      []
    end
  end
end
