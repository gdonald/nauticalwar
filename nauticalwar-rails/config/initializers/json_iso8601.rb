# frozen_string_literal: true

ActiveSupport::JSON::Encoding.time_precision = 0 if Rails.env.test?
