# frozen_string_literal: true

FactoryBot.define do
  factory :ship do
    sequence :name do |n|
      "ship#{n}"
    end
    size 2
  end
end
