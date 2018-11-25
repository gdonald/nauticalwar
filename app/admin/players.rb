# frozen_string_literal: true

ActiveAdmin.register Player do # rubocop:disable Metrics/BlockLength
  permit_params :email, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :email
    column 'Created', :created_at
    column 'Confirmed', :confirmed_at
    column 'Logins', :sign_in_count
    column 'Last', :current_sign_in_at
    column :wins
    column :losses
    column :rating
    actions
  end

  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :confirmed_at, as: :date_range
  filter :created_at

  form do |f|
    f.inputs do
      f.input :email
      f.input :password
      f.input :password_confirmation
      f.input :confirmed_at
    end
    f.actions
  end
end
