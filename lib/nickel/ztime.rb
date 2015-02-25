require 'time'

module Nickel
  class ZTime
    include Comparable

    # \@firm will be used to indicate user provided am/pm
    attr_accessor :firm

    # \@time is always stored on 24 hour clock, but we could initialize a Time object with ZTime.new("1020", :pm)
    # we will convert this to 24 hour clock and set \@firm = true
    def initialize(hhmmss = nil, am_pm = nil)
      t = hhmmss ? hhmmss : ::Time.new.strftime('%H%M%S')
      t.gsub!(/:/, '') # remove any hyphens, so a user can initialize with something like "2008-10-23"
      self.time = t
      if am_pm
        adjust_for(am_pm)
      else
        adjust_for_workday
      end
    end

    def time
      @time
    end

    def time=(hhmmss)
      @time = lazy(hhmmss)
      @firm = false
      validate
    end

    def hour_str
      @time[0..1]
    end

    # @deprecated Please use {#min_str} instead
    def minute_str
      warn '[DEPRECATION] `minute_str` is deprecated.  Please use `min_str` instead.'
      min_str
    end

    def min_str
      @time[2..3]
    end

    # @deprecated Please use {#sec_str} instead
    def second_str
      warn '[DEPRECATION] `second_str` is deprecated.  Please use `sec_str` instead.'
      sec_str
    end

    def sec_str
      @time[4..5]
    end

    def hour
      hour_str.to_i
    end

    # @deprecated Please use {#min} instead
    def minute
      warn '[DEPRECATION] `minute` is deprecated.  Please use `min` instead.'
      min
    end

    def min
      min_str.to_i
    end

    # @deprecated Please use {#sec} instead
    def second
      warn '[DEPRECATION] `second` is deprecated.  Please use `sec` instead.'
      sec
    end

    def sec
      sec_str.to_i
    end

    # add\_ methods return new ZTime object
    # add\_ methods take an optional block, the block will be passed the number of days that have passed;
    # i.e. adding 48 hours will pass a 2 to the block, this is handy for something like this:
    # time.add_hours(15) {|x| date.add_days(x)}
    def add_minutes(number, &block)
      # new minute is going to be (current minute + number) % 60
      # number of hours to add is (current minute + number) / 60
      hours_to_add = (min + number) / 60
      # note add_hours returns a new time object
      if block_given?
        o = add_hours(hours_to_add, &block)
      else
        o = add_hours(hours_to_add)
      end
      o.change_minute_to((o.min + number) % 60)  # modifies self
    end

    def add_hours(number, &block)
      o = dup
      if block_given?
        yield((o.hour + number) / 24)
      end
      o.change_hour_to((o.hour + number) % 24)
    end

    # NOTE: change_ methods modify self.
    def change_hour_to(h)
      self.time = ZTime.format_time(h, min_str, sec_str)
      self
    end

    def change_minute_to(m)
      self.time = ZTime.format_time(hour_str, m, sec_str)
      self
    end

    def change_second_to(s)
      self.time = ZTime.format_time(hour_str, min_str, s)
      self
    end

    def readable
      @time[0..1] + ':' + @time[2..3] + ':' + @time[4..5]
    end

    def readable_12hr
      hour_on_12hr_clock + ':' + @time[2..3] + " #{am_pm}"
    end

    def hour_on_12hr_clock
      h = hour % 12
      h += 12 if h == 0
      h
    end

    def is_am?
      warn '[DEPRECATION] `is_am?` is deprecated.  Please use `am?` instead.'
      am?
    end

    def am?
      hour < 12   # 0 through 11 on 24hr clock
    end

    def am_pm
      am? ? 'am' : 'pm'
    end

    def <=>(other)
      return nil unless [:hour, :min, :sec].all? { |m| other.respond_to?(m) }

      if before?(other)
        -1
      elsif after?(other)
        1
      else
        0
      end
    end

    def to_s
      time
    end

    def to_time
      Time.parse("#{hour}:#{min}:#{sec}")
    end

    class << self
      # send an array of ZTime objects, this will make a guess at whether they should be am/pm if the user did not specify
      # NOTE ORDER IS IMPORTANT: times[0] is assumed to be BEFORE times[1]
      def am_pm_modifier(*time_array)
        # find firm time indices
        firm_time_indices = []
        time_array.each_with_index { |t, i| firm_time_indices << i if t.firm }

        if firm_time_indices.empty?
          # pure guess
          # DO WE REALLY WANT TO DO THIS?
          time_array.each_index do |i|
            # user gave us nothing
            next if i == 0
            time_array[i].guess_modify_such_that_is_after(time_array[i - 1])
          end
        else
          # first handle soft times up to first firm time
          min_boundary = 0
          max_boundary = firm_time_indices[0]
          (min_boundary...max_boundary).to_a.reverse.each do |i|      # this says, iterate backwards starting from max_boundary, but not including it, until the min boundary
            time_array[i].modify_such_that_is_before(time_array[i + 1])
          end

          firm_time_indices.each_index do |j|
            # now handle all times after first firm time until the next firm time
            min_boundary = firm_time_indices[j]
            max_boundary = firm_time_indices[j + 1] || time_array.size
            (min_boundary + 1...max_boundary).each do |i|     # any boundary problems here? What if there is only 1 time?  Nope.
              time_array[i].modify_such_that_is_after(time_array[i - 1])
            end
          end
        end
      end

      def am_to_24hr(h)
        # note 12am is 00
        h % 12
      end

      def pm_to_24hr(h)
        h == 12 ? 12 : h + 12
      end

      def format_hour(h)
        h.to_s.rjust(2, '0')
      end

      def format_minute(m)
        m.to_s.rjust(2, '0')
      end

      def format_second(s)
        s.to_s.rjust(2, '0')
      end

      # formats the hours, minutes and seconds into the format expected by the ZTime constructor
      def format_time(hours, minutes = 0, seconds = 0)
        format_hour(hours) + format_minute(minutes) + format_second(seconds)
      end

      # Interpret Time is an important one, set some goals:
      #     match all of the following
      #     a.) 5,   12,   530,    1230,     2000
      #     b.) 5pm, 12pm, 530am,  1230am,
      #     c.)            5:30,   12:30,    20:00
      #     d.)            5:3,    12:3,     20:3    ...  that's not needed but we supported it in version 1, this would be 5:30 and 12:30
      #     e.)            5:30am, 12:30am
      #     20:00am, 20:00pm ... ZTime will flag these as invalid, so it is ok if we match them here
      def interpret(str)
        a_b   = /^(\d{1,4})(am|pm)?$/                     # handles cases (a) and (b)
        c_d_e = /^(\d{1,2}):(\d{1,2})(am|pm)?$/           # handles cases (c), (d), and (e)
        if mdata = str.match(a_b)
          am_pm = mdata[2]
          # this may look a bit confusing, but all we are doing is interpreting
          # what the user meant based on the number of digits they provided
          if mdata[1].length <= 2
            # e.g. "11" means 11:00
            hstr = mdata[1]
            mstr = '0'
          elsif mdata[1].length == 3
            # e.g. "530" means 5:30
            hstr = mdata[1][0..0]
            mstr = mdata[1][1..2]
          elsif mdata[1].length == 4
            # e.g. "1215" means 12:15
            hstr = mdata[1][0..1]
            mstr = mdata[1][2..3]
          end
        elsif mdata = str.match(c_d_e)
          am_pm = mdata[3]
          hstr = mdata[1]
          mstr = mdata[2]
        else
          return nil
        end
        # in this case we do not care if time fails validation, if it does, it just means we haven't found a valid time, return nil
        begin ZTime.new(ZTime.format_time(hstr, mstr), am_pm) rescue return nil end
      end
    end

    # this can very easily be cleaned up
    def modify_such_that_is_before(time2)
      fail 'ZTime#modify_such_that_is_before says: trying to modify time that has @firm set' if @firm
      fail 'ZTime#modify_such_that_is_before says: time2 does not have @firm set' unless time2.firm
      # self cannot have @firm set, so all hours will be between 1 and 12
      # time2 is an end time, self could be its current setting, or off by 12 hours

      # self to time2 --> self to time2
      # 12   to 2am   --> 1200 to 0200
      # 12   to 12am  --> 1200 to 0000
      # 1220 to 12am  --> 1220 to 0000
      # 11 to 2am  or 1100 to 0200
      if self > time2
        if hour == 12 && time2.hour == 0
          # do nothing
        else
          hour == 12 ? change_hour_to(0) : change_hour_to(hour + 12)
        end
      elsif self < time2
        if time2.hour >= 12 && ZTime.new(ZTime.format_time(time2.hour - 12, time2.min_str, time2.sec_str)) > self
          # 4 to 5pm  or 0400 to 1700
          change_hour_to(hour + 12)
        else
          # 4 to 1pm  or 0400 to 1300
          # do nothing
        end
      else
        # the times are equal, and self can only be between 0100 and 1200, so move self forward 12 hours, unless hour is 12
        hour == 12 ? change_hour_to(0) : change_hour_to(hour + 12)
      end
      self.firm = true
      self
    end

    def modify_such_that_is_after(time1)
      fail 'ZTime#modify_such_that_is_after says: trying to modify time that has @firm set' if @firm
      fail 'ZTime#modify_such_that_is_after says: time1 does not have @firm set' unless time1.firm
      # time1 to self --> time1 to self
      # 8pm   to 835  --> 2000 to 835
      # 835pm to 835  --> 2035 to 835
      # 10pm  to 11   --> 2200 to 1100
      # 1021pm to 1223--> 2221 to 1223
      # 930am  to 5 --->  0930 to 0500
      # 930pm  to 5 --->  2130 to 0500
      if self < time1
        unless time1.hour >= 12 && ZTime.new(ZTime.format_time(time1.hour - 12, time1.min_str, time1.sec_str)) >= self
          hour == 12 ? change_hour_to(0) : change_hour_to(hour + 12)
        end
      elsif self > time1
        # # time1 to self --> time1 to self
        # # 10am  to 11   --> 1000  to 1100
        # #
        # if time1.hour >= 12 && ZTime.new(ZTime.format_time(time1.hour - 12, time1.min_str, time1.sec_str)) > self
        #   change_hour_to(self.hour + 12)
        # else
        #   # do nothing
        # end
      else
        # the times are equal, and self can only be between 0100 and 1200, so move self forward 12 hours, unless hour is 12
        hour == 12 ? change_hour_to(0) : change_hour_to(hour + 12)
      end
      self.firm = true
      self
    end

    # use this if we don't have a firm time to modify off
    def guess_modify_such_that_is_after(time1)
      # time1 to self    time1 to self
      # 9    to    5 --> 0900 to 0500
      # 9   to     9 --> 0900 to 0900
      # 12   to   12 --> 1200 to 1200
      # 12 to 6   --->   1200 to 0600
      if time1 >= self
        # crossed boundary at noon
        hour == 12 ? change_hour_to(0) : change_hour_to(hour + 12)
      end
    end

    private

    def before?(other)
      (hour < other.hour) || (hour == other.hour && (min < other.min || (min == other.min && sec < other.sec)))
    end

    def after?(other)
      (hour > other.hour) || (hour == other.hour && (min > other.min || (min == other.min && sec > other.sec)))
    end

    def adjust_for(am_pm)
      # how does validation work?  Well, we already know that @time is valid, and once we modify we call time= which will
      # perform validation on the new time.  That won't catch something like this though:  ZTime.new("2215", :am)
      # so we will check for that here.
      # If user is providing :am or :pm, the hour must be between 1 and 12
      fail 'ZTime#adjust_for says: you specified am or pm with 1 > hour > 12' unless hour >= 1 && hour <= 12
      if am_pm == :am || am_pm == 'am'
        change_hour_to(ZTime.am_to_24hr(hour))
      elsif am_pm == :pm || am_pm == 'pm'
        change_hour_to(ZTime.pm_to_24hr(hour))
      else
        fail 'ZTime#adjust_for says: you passed an invalid value for am_pm, use :am or :pm'
      end
      @firm = true
    end

    # sm ---------------
    def adjust_for_workday
      defaults = User.new
      sod_min = defaults.starting_day[:hour] * 60 + defaults.starting_day[:min]
      eod_min = defaults.ending_day[:hour] * 60 + defaults.ending_day[:min]
      if hour*60 + min < sod_min and hour*60 + min <= eod_min           # leave in am if converted to pm is too late
        change_hour_to(ZTime.pm_to_24hr(hour))
      end
    end

    def validate
      fail 'ZTime#validate says: invalid time' unless valid
    end

    def valid
      @time.length == 6 && @time !~ /\D/ && valid_hour && valid_minute && valid_second
    end

    def valid_hour
      hour >= 0 && hour < 24
    end

    def valid_minute
      min >= 0 && min < 60
    end

    def valid_second
      sec >= 0 && sec < 60
    end

    def lazy(s)
      # someone isn't following directions, but we will let it slide
      s.length == 1 && s = "0#{s}0000"        # only provided h
      s.length == 2 && s << '0000'            # only provided hh
      s.length == 4 && s << '00'              # only provided hhmm
      s
    end
  end
end
