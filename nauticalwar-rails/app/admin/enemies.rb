# frozen_string_literal: true

ActiveAdmin.register Enemy do
  actions :all, except: %i[show new edit]

  index do
    selectable_column
    id_column
    column :player1
    column :player2
    column 'Created', :created_at
    column 'Updated', :updated_at
    actions
  end

  filter :player1_id
  filter :player2_id
end
