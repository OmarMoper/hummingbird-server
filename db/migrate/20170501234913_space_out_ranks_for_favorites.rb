require 'update_in_batches'

class SpaceOutRanksForFavorites < ActiveRecord::Migration
  using UpdateInBatches

  disable_ddl_transaction!

  def change
    execute <<-SQL.squish
      CREATE TEMPORARY VIEW fav_ranks (id, rank) AS
        SELECT id, ((row_number() OVER (
          PARTITION BY user_id, item_type
          ORDER BY fav_rank ASC,
                   created_at ASC
        )) * 20) AS rank
        FROM favorites
    SQL
    say_with_time 'Updating rank column for favorites' do
      Favorite.all.update_in_batches(<<-SQL.squish)
        fav_rank = (
          SELECT rank FROM fav_ranks WHERE fav_ranks.id = favorites.id
        )
      SQL
    end
  end
end
