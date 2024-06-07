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
    when 2 then 'two'
    when 3 then 'three'
    when 4 then 'four'
    when 5 then 'five'
    else 'one'
    end
  end

  def rank_name(rank) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize
    case rank
    when 'e2' then 'Seaman Apprentice'
    when 'e3' then 'Seaman'
    when 'e4' then 'Petty Officer Third Class'
    when 'e5' then 'Petty Officer Second Class'
    when 'e6' then 'Petty Officer First Class'
    when 'e7' then 'Chief Petty Officer'
    when 'e8' then 'Senior Chief Petty Officer'
    when 'e9' then 'Master Chief Petty Officer'
    when 'o1' then 'Ensign'
    when 'o2' then 'Lieutenant Junior Grade'
    when 'o3' then 'Lieutenant'
    when 'o4' then 'Lieutenant Commander'
    when 'o5' then 'Commander'
    when 'o6' then 'Captain'
    when 'o7' then 'Rear Admiral Lower Half'
    when 'o8' then 'Rear Admiral'
    when 'o9' then 'Vice Admiral'
    when 'o10' then 'Admiral'
    when 'o11' then 'Fleet Admiral'
    else 'Seaman Recruit'
    end
  end
end
