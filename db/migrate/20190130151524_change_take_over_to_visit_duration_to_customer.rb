class ChangeTakeOverToVisitDurationToCustomer < ActiveRecord::Migration
  def change
    rename_column :customers, :take_over, :visit_duration
  end
end
