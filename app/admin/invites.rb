# frozen_string_literal: true

ActiveAdmin.register Invite do
  permit_params :rated, :five_shot

  index do
    selectable_column
    id_column
    column :player_1
    column :player_2
    column :rated
    column :five_shot
    column :time_limit
    column 'Created', :created_at
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
