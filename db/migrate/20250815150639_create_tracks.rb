class CreateTracks < ActiveRecord::Migration[7.1]
  def change
    create_table :tracks do |t|
      t.string :title, null: false
      t.string :artist
      t.string :source, null: false # "youtube"
      t.string :external_id, null: false
      t.integer :duration
      t.string :thumbnail_url
      t.timestamps
    end
    add_index :tracks, :external_id
  end
end
