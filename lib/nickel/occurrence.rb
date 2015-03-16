module Nickel
  # Some notes about this class, type can take the following values:
  # :single, :daily, :weekly, :daymonthly, :datemonthly,
  Occurrence = Struct.new(:type, :start_date, :end_date, :start_time, :end_time, :interval, :day_of_week, :week_of_month, :date_of_month) do

    def initialize(h)
      h.each { |k, v| send("#{k}=", v) }
    end

    def inspect
      '#<Occurrence ' + members.select { |m| self[m] }.map { |m| %(#{m}: #{self[m]}) }.join(', ') + '>'
    end

    def finalize(cur_date)
      cur_date = start_date unless start_date.nil?
      case type
      when :daily then finalize_daily(cur_date)
      when :weekly then finalize_weekly(cur_date)
      when :datemonthly then finalize_datemonthly(cur_date)
      when :daymonthly then finalize_daymonthly(cur_date)
      end
    end

    private

    def finalize_daily(cur_date)
      # require an ending date
      if !end_date.nil?
        self.start_date = cur_date
      end
    end

    def finalize_weekly(cur_date)
      # if the start and end dates don't match the day of the week, adjust
      unless start_date.nil?
        new_start = self.start_date.this(self.day_of_week)
        if new_start < self.start_date
          self.start_date = self.start_date.next(self.day_of_week)
        else
          self.start_date = new_start
        end
      end
      unless end_date.nil?
        new_end = self.end_date.this(self.day_of_week)
        if new_end > self.end_date
          self.end_date = self.start_date.prior(self.day_of_week)
        else
          self.end_date = new_end
        end
      end
    end

    def finalize_datemonthly(cur_date)
      if cur_date.day <= date_of_month
        self.start_date = cur_date.add_days(date_of_month - cur_date.day)
      else
        self.start_date = cur_date.add_months(1).beginning_of_month.add_days(date_of_month - 1)
      end
    end

    def finalize_daymonthly(cur_date)
      # in this case we also want to change week_of_month val to -1 if
      # it is currently 5.  I used 5 to represent "last" in the
      # previous version of the parser, but a more standard format is
      # to use -1
      self.week_of_month = -1 if week_of_month == 5

      self.start_date = cur_date.get_date_from_day_and_week_of_month(day_of_week, week_of_month)
    end
  end
end
