class ChangeTakeOverToDurationToVisit < ActiveRecord::Migration
  def change
    rename_column :visits, :take_over, :duration
  end
end
