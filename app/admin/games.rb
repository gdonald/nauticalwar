# frozen_string_literal: true

ActiveAdmin.register Game do # rubocop:disable Metrics/BlockLength
  permit_params :rated, :five_shot

  index do
    selectable_column
    id_column
    column :player_1
    column 'Layout', :player_1_layed_out
    column :player_2
    column 'Layout', :player_2_layed_out
    column :rated
    column 'Five', :five_shot
    column :turn
    column :winner
    column 'Limit', :time_limit
    column 'Created', :created_at
    column 'Updated', :updated_at
    actions
  end

  filter :rated
  filter :five_shot

  form do |f|
    f.inputs do
      f.input :rated
      f.input :five_shot
    end
    f.actions
  end
end
