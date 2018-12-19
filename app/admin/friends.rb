# frozen_string_literal: true

ActiveAdmin.register Friend do
  actions :all, except: %i[show new edit]

  index do
    selectable_column
    id_column
    column :player_1
    column :player_2
    column 'Created', :created_at
    column 'Updated', :updated_at
    actions
  end

  filter :player_1_id
  filter :player_2_id
end
