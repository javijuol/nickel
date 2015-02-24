class HolidaysWrapper < Holidays
  # sm - reads every holiday in region, including informal, and returns a date or nil
  # the date range is for the 12 month period following now
  def self.find_name(region, name)
    Holidays.between(Date.today,Date.today>>12, region, :informal).each do |htest|
      if htest[:name] == name
        return htest[:date]
      end
    end
    return nil
  end
end