class Unsub < ApplicationRecord
  validates :email, presence: true, uniqueness: true

  def self.found?(obj)
    case obj
    when String
      Unsub.find_by(email: obj)
    when Player
      Unsub.find_by(email: obj.email)
    else
      raise 'Unknown type'
    end
  end
end
