# frozen_string_literal: true

ActiveAdmin.register Player do # rubocop:disable Metrics/BlockLength
  permit_params :email, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :email
    column :name
    column :admin
    column :bot
    column :guest
    column :strength
    column :wins
    column :losses
    column :rating
    column 'Last', :last_sign_in_at
    column 'Created', :created_at
    column 'Confirmed', :confirmed_at
    actions
  end

  filter :name
  filter :email
  filter :last_sign_in_at
  filter :confirmed_at, as: :date_range
  filter :created_at

  form do |f|
    f.inputs do
      f.input :name
      f.input :email
      f.input :password
      f.input :password_confirmation
      f.input :confirmed_at
    end
    f.actions
  end
end
