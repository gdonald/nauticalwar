# frozen_string_literal: true

FactoryBot.define do
  factory :layout do
    x { 0 }
    y { 0 }
    vertical { true }

    trait :horizontal do
      vertical { false }
    end
  end
end
