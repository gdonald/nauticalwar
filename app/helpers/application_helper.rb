# frozen_string_literal: true

module ApplicationHelper

  def yes_no(bool)
    bool ? 'Yes' : 'No'
  end

  def time_limit_in_words(seconds)
    Invite.time_limits[seconds.to_s.to_sym]
  end

  def time_left(seconds)
    return '0:00' if seconds <= 0

    time_ago_in_words(Time.current + seconds.seconds)
  end

  def shots_per_turn_name(obj)
    case obj.shots_per_turn
    when 1 then 'one'
    when 2 then 'two'
    when 3 then 'three'
    when 4 then 'four'
    when 5 then 'five'
    else ''
    end
  end

  def rank_name(rank)
    case rank
    when 'e2'
      'Seaman Apprentice'
    when 'e3'
      'Seaman'
    when 'e4'
      'Petty Officer Third Class'
    when 'e5'
      'Petty Officer Second Class'
    when 'e6'
      'Petty Officer First Class'
    when 'e7'
      'Chief Petty Officer'
    when 'e8'
      'Senior Chief Petty Officer'
    when 'e9'
      'Master Chief Petty Officer'
    when 'o1'
      'Ensign'
    when 'o2'
      'Lieutenant Junior Grade'
    when 'o3'
      'Lieutenant'
    when 'o4'
      'Lieutenant Commander'
    when 'o5'
      'Commander'
    when 'o6'
      'Captain'
    when 'o7'
      'Rear Admiral Lower Half'
    when 'o8'
      'Rear Admiral'
    when 'o9'
      'Vice Admiral'
    when 'o10'
      'Admiral'
    when 'o11'
      'Fleet Admiral'
    else
      'Seaman Recruit'
    end
  end

end
