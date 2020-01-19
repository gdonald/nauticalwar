# frozen_string_literal: true

ActiveAdmin.register Invite do
  permit_params :rated, :shots_per_turn

  index do
    selectable_column
    id_column
    column :player_1
    column :player_2
    column :rated
    column :shots_per_turn
    column :time_limit
    column 'Created', :created_at
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
