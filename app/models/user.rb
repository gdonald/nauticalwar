class User < ApplicationRecord

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true, length: { maximum: 12 }

  def self.generate_password(length)
    (('a'..'z').to_a + (10..99).to_a + ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_'] * 10).shuffle[0, length].join
  end
  
end
