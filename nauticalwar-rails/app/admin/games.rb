# frozen_string_literal: true

ActiveAdmin.register Game do # rubocop:disable Metrics/BlockLength
  permit_params :rated, :shots_per_turn

  index do
    selectable_column
    id_column
    column :player1
    column 'Layout', :player1_layed_out
    column :player2
    column 'Layout', :player2_layed_out
    column :rated
    column 'Shots', :shots_per_turn
    column :turn
    column :winner
    column 'Limit', :time_limit
    column 'Created', :created_at
    column 'Updated', :updated_at
    actions
  end

  filter :rated
  filter :shots_per_turn

  form do |f|
    f.inputs do
      f.input :rated
      f.input :shots_per_turn
    end
    f.actions
  end
end
