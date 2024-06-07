# frozen_string_literal: true

ActiveAdmin.register Unsub do
  permit_params :email

  index do
    selectable_column
    id_column
    column :email
    column 'Created', :created_at
    actions
  end

  filter :email
  filter :created_at

  form do |f|
    f.inputs do
      f.input :email
    end
    f.actions
  end
end
