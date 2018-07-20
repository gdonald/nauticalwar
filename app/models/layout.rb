class Layout < ApplicationRecord

  belongs_to :user
  belongs_to :game
  belongs_to :ship

  validates :user, presence: true
  validates :game, presence: true
  validates :ship, presence: true
  validates :x, presence: true, inclusion: { in: (0..9).to_a }
  validates :y, presence: true, inclusion: { in: (0..9).to_a }

  validates :user, uniqueness: { scope: %i[game ship x y] }

  validates :vertical, presence: true

  def set_location
    vertical = [0, 1].sample.zero?
    if vertical

    else

    end
    
=begin
    if self.vertical:
            c = random.randint( 0, 9 )
            r = random.randint( 0, 9 ) - self.ship.size
            r = 0 if r < 0 else r
            r = 9 if r > 9 else r
            c = 0 if c < 0 else c
            c = 9 if c > 9 else c
            if r > 10 - self.ship.size:
                r = 10 - self.ship.size
            for x in range( r, r + self.ship.size ):
                if self.game.is_hit( self.user, c, x ):
                    self.set_random_location()
                    return
        else:
            c = random.randint( 0, 9 ) - self.ship.size
            r = random.randint( 0, 9 )
            r = 0 if r < 0 else r
            r = 9 if r > 9 else r
            c = 0 if c < 0 else c
            c = 9 if c > 9 else c
            if c > 10 - self.ship.size:
                c = 10 - self.ship.size
            for x in range( c, c + self.ship.size ):
                if self.game.is_hit( self.user, x, r ):
                    self.set_random_location()
                    return
        self.x = c
        self.y = r
=end
  end
  
end
