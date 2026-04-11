require "test_helper"

class TrackTest < ActiveSupport::TestCase
  # ---- extract_youtube_id ----

  test "extract_youtube_id parses standard watch?v= URL" do
    assert_equal "dQw4w9WgXcQ", Track.extract_youtube_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
  end

  test "extract_youtube_id parses short youtu.be URL" do
    assert_equal "dQw4w9WgXcQ", Track.extract_youtube_id("https://youtu.be/dQw4w9WgXcQ")
  end

  test "extract_youtube_id parses URL with timestamp parameter" do
    assert_equal "dQw4w9WgXcQ", Track.extract_youtube_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42")
  end

  test "extract_youtube_id returns nil for non-youtube URL" do
    assert_nil Track.extract_youtube_id("https://vimeo.com/123456")
  end

  test "extract_youtube_id returns nil for random string" do
    assert_nil Track.extract_youtube_id("not a url at all")
  end

  test "extract_youtube_id returns nil for empty string" do
    assert_nil Track.extract_youtube_id("")
  end

  test "extract_youtube_id returns nil for nil" do
    assert_nil Track.extract_youtube_id(nil)
  end

  # ---- from_youtube_url ----

  test "from_youtube_url raises ArgumentError for invalid URL" do
    assert_raises(ArgumentError) { Track.from_youtube_url("https://vimeo.com/123") }
  end

  test "from_youtube_url raises ArgumentError for nil" do
    assert_raises(ArgumentError) { Track.from_youtube_url(nil) }
  end

  test "from_youtube_url returns existing track without HTTP call" do
    existing = tracks(:youtube_track)
    url = "https://www.youtube.com/watch?v=#{existing.external_id}"

    # No stub needed — find_or_create_by! finds the record without calling the block
    track = Track.from_youtube_url(url)
    assert_equal existing.id, track.id
    assert_equal existing.title, track.title
  end

  test "from_youtube_url creates new track using oembed metadata" do
    vid = "test_vid_#{SecureRandom.hex(4)}"
    url = "https://www.youtube.com/watch?v=#{vid}"
    oembed_body = JSON.generate(title: "Test Song", thumbnail_url: "https://img.example.com/t.jpg")

    fake_http = new_fake_http(200, oembed_body)
    Net::HTTP.stub(:start, ->(*_args, &block) { block.call(fake_http) }) do
      track = Track.from_youtube_url(url)
      assert_equal "Test Song", track.title
      assert_equal "https://img.example.com/t.jpg", track.thumbnail_url
      assert_equal "youtube", track.source
      assert_equal vid, track.external_id
    ensure
      Track.find_by(source: "youtube", external_id: vid)&.destroy
    end
  end

  test "from_youtube_url falls back to default title when oembed fails" do
    vid = "test_vid_#{SecureRandom.hex(4)}"
    url = "https://www.youtube.com/watch?v=#{vid}"

    fake_http = new_fake_http(404, "Not Found")
    Net::HTTP.stub(:start, ->(*_args, &block) { block.call(fake_http) }) do
      track = Track.from_youtube_url(url)
      assert_equal "YouTube ##{vid}", track.title
    ensure
      Track.find_by(source: "youtube", external_id: vid)&.destroy
    end
  end

  private

  # Builds a minimal fake Net::HTTP session object that returns the given
  # HTTP status code and body for any GET request.
  def new_fake_http(status_code, body)
    res = Net::HTTPResponse::CODE_TO_OBJ[status_code.to_s].new("1.1", status_code, "")
    res.instance_variable_set(:@body, body)
    res.instance_variable_set(:@read, true)

    fake = Object.new
    fake.define_singleton_method(:read_timeout=) { |_v| }
    fake.define_singleton_method(:open_timeout=) { |_v| }
    fake.define_singleton_method(:get) { |_path| res }
    fake
  end
end
