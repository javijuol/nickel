require 'nickel/construct'
require 'nickel/zdate'
require 'nickel/ztime'


module Nickel
  class ConstructFinder
    attr_reader :constructs, :components, :last_pos, :pair_groups

    def initialize(query, curdate, curtime)
      @curdate = curdate
      @curtime = curtime
      @components = query.split
      @pos = 0    # iterator
      @constructs = []
      @pair_groups = []               # an array of all found pairs
      @week_index = 0                 # use to establish the week for any daynames that follow, e.g. next week on Wednesay - the 'next week' sets the index to 1 and then Wed is calced accordingly
      @negate = false                 # use for date/times to exclude
    end

    # NOTE - The program uses the concept of a wrapper for date or time ranges without a defined starting date
    # type 0 flags the start of a date range and type 1 flags the end of a date range
    # type 2 flags a range in days and type 3 flags a range in weeks and type 4 in months
    # when there are anchoring dates, they are placed in the occurrence array AFTER the wrappers

    # dates and times need to be paired based on prepositional and conjunction modifiers
    # after creating the constructs, order them into strict date+time sequence for the interpreter

    def run
      while @pos < @components.size
        find_constructs
        @pos += 1
        if constructs.length > 0     #sm - at least one construct found - save the last postion of the last construct
           @last_pos = constructs[constructs.length-1].comp_end
        end
      end
      convert_wrapper1_into_date_ranges
      marry_date_time_constructs
    end

    def reset_instance_vars
      @day_index = nil
      @month_index = nil
      @week_num = nil
      @date_array = nil
      @length = nil
      @time1 = nil
      @time2 = nil
      @date1 = nil
      @date2 = nil
    end

    def new_find_constructs

    end








    def find_constructs
      reset_instance_vars

      if match_every
        if match_every_dayname
          found_every_dayname                             # every tue
        elsif match_every_day
          found_every_day                                 # every day
        elsif match_every_other
          if match_every_other_dayname
            found_every_other_dayname                     # every other fri
          elsif match_every_other_day
            found_every_other_day                         # every other day
          end
        elsif match_every_3rd
          if match_every_3rd_dayname
            found_every_3rd_dayname                       # every third fri
          elsif match_every_3rd_day
            found_every_3rd_day                           # every third day
          end
        end

      elsif match_repeats
        if match_repeats_daily
          found_repeats_daily                             # repeats daily
        elsif match_repeats_altdaily
          found_repeats_altdaily                          # repeats altdaily
        elsif match_repeats_weekly_vague
          found_repeats_weekly_vague                      # repeats weekly
        elsif match_repeats_altweekly_vague
          found_repeats_altweekly_vague                   # repeats altweekly
        elsif match_repeats_monthly
          if match_repeats_daymonthly
            found_repeats_daymonthly                      # repeats monthly 1st fri
          elsif match_repeats_datemonthly
            found_repeats_datemonthly                     # repeats monthly 22nd
          end
        elsif match_repeats_altmonthly
          if match_repeats_altmonthly_daymonthly
            found_repeats_altmonthly_daymonthly           # repeats altmonthly 1st fri
          elsif match_repeats_altmonthly_datemonthly
            found_repeats_altmonthly_datemonthly          # repeats altmonthly 22nd
          end
        elsif match_repeats_threemonthly
          if match_repeats_threemonthly_daymonthly
            found_repeats_threemonthly_daymonthly         # repeats threemonthly 1st fri
          elsif match_repeats_threemonthly_datemonthly
            found_repeats_threemonthly_datemonthly        # repeats threemonthly 22nd
          end
        end

      elsif match_for_x
        if match_for_x_days
          found_for_x_days                                # for 10 days
        elsif match_for_x_weeks
          found_for_x_weeks                               # for 10 weeks
        elsif match_for_x_months
          found_for_x_months                              # for 10 months
        end

# sm- ADDED        
      elsif match_previous
        if match_previous_weekend
          found_previous_weekend                              
        elsif match_previous_dayname
          found_previous_dayname                              # previous tuesday
        elsif match_previous_x
          if match_previous_x_days
            found_previous_x_days                             # previous 5 days   --- shouldn't this be a wrapper?
          elsif match_previous_x_weeks
            found_previous_x_weeks                            # previous 5 weeks  --- shouldn't this be a wrapper?
          elsif match_previous_x_months
            found_previous_x_months                           # previous 5 months --- shouldn't this be a wrapper?
          elsif match_previous_x_years
            found_previous_x_years                            # previous 5 years  --- shouldn't this be a wrapper?
          end
        elsif match_previous_week
          found_previous_week
        elsif match_previous_month
          found_previous_month                                # previous month (implies 10/1 to 10/31)
        end

      elsif match_thiscoming                              # the logic for this and next dayname has been changed to refer to the
        if match_thiscoming_dayname                       # current or following week. If the user means the next occrence,
          found_thiscoming_dayname                        # then we are using the token 'this coming'
        end
      elsif match_the_following_week
        found_the_following_week
      elsif match_this
        if match_this_dayname
          found_thiscoming_dayname          # sm - I changed this to always find the next ocurrence since meetings are always in the future
        elsif match_this_week
          found_this_week                                 # this week
        elsif match_this_month
          found_this_month                                # this month (implies 9/1 to 9/30)
        end                                                                                                 # SHOULDN'T "this" HAVE "this weekend" ???
      elsif match_the_following_month
        found_the_following_month
      elsif match_next
        if match_next_weekend
          found_next_weekend                              # next weekend --- never hit?
        elsif match_next_dayname
          found_next_dayname                              # next tuesday
        elsif match_next_x
          if match_next_x_days
            found_next_x_days                             # next 5 days   --- shouldn't this be a wrapper?
          elsif match_next_x_weeks
            found_next_x_weeks                            # next 5 weeks  --- shouldn't this be a wrapper?
          elsif match_next_x_months
            found_next_x_months                           # next 5 months --- shouldn't this be a wrapper?
          elsif match_next_x_years
            found_next_x_years                            # next 5 years  --- shouldn't this be a wrapper?
          end
        elsif match_next_week
          found_next_week
        elsif match_next_month
          found_next_month                                # next month (implies 10/1 to 10/31)
        end

      elsif match_week_after_next
        found_week_after_next

      elsif match_theweekafter
        if match_theweekafter_date
          found_theweekafter_date
        end

      elsif match_theweekbefore
        if match_theweekbefore_date
          found_theweekbefore_date
        end

      elsif match_thedayafter
        if match_thedayafter_tomorrow
          found_thedayafter_tomorrow
        elsif match_thedayafter_date
          found_thedayafter_date
        end

      elsif match_thedaybefore
        if match_thedaybefore_date
          found_thedaybefore_date
        end

      elsif match_week
        if match_week_of_date
          found_week_of_date                              # week of 1/2
        elsif match_week_through_date
          found_week_through_date                         # week through 1/2  (as in, week ending 1/2)
        end

      elsif match_x_weeks_from
        if match_x_weeks_from_dayname
          found_x_weeks_from_dayname                      # 5 weeks from tuesday
        elsif match_x_weeks_from_this_dayname
          found_x_weeks_from_this_dayname                 # 5 weeks from this tuesday
        elsif match_x_weeks_from_next_dayname
          found_x_weeks_from_next_dayname                 # 5 weeks from next tuesday
        elsif match_x_weeks_from_tomorrow
          found_x_weeks_from_tomorrow                     # 5 weeks from tomorrow
        elsif match_x_weeks_from_now
          found_x_weeks_from_now                          # 5 weeks from now
        elsif match_x_weeks_from_yesterday
          found_x_weeks_from_yesterday                    # 5 weeks from yesterday
        end

      elsif match_nth_week_of_month
            found_nth_week_of_month

      elsif match_x_months_from
        if match_x_months_from_dayname
          found_x_months_from_dayname                   # 2 months from wed
        elsif match_x_months_from_this_dayname
          found_x_months_from_this_dayname              # 2 months from this wed
        elsif match_x_months_from_next_dayname
          found_x_months_from_next_dayname              # 2 months from next wed
        elsif match_x_months_from_tomorrow
          found_x_months_from_tomorrow                  # 2 months from tomorrow
        elsif match_x_months_from_now
          found_x_months_from_now                       # 2 months from now
        elsif match_x_months_from_yesterday
          found_x_months_from_yesterday                 # 2 months from yesterday
        end

      elsif match_x_days_from
        if match_x_days_from_now
          found_x_days_from_now                         # 5 days from now
        elsif match_x_days_from_dayname
          found_x_days_from_dayname                     # 5 days from monday
        end

      elsif match_x_dayname_from
        if match_x_dayname_from_now
          found_x_dayname_from_now                      # 2 fridays from now
        elsif match_x_dayname_from_tomorrow
          found_x_dayname_from_tomorrow                 # 2 fridays from tomorrow
        elsif match_x_dayname_from_yesterday
          found_x_dayname_from_yesterday                # 2 fridays from yesterday
        elsif match_x_dayname_from_this
          found_x_dayname_from_this                     # 2 fridays from this one
        elsif match_x_dayname_from_next
          found_x_dayname_from_next                     # 2 fridays from next friday
        end

      elsif match_x_minutes_from_now
        found_x_minutes_from_now                        # 5 minutes from now
      elsif match_x_hours_from_now
        found_x_hours_from_now                          # 5 hours from now

      elsif match_ordinal_dayname
        if match_ordinal_dayname_this_month
          found_ordinal_dayname_this_month              # 2nd friday this month
        elsif match_ordinal_dayname_next_month
          found_ordinal_dayname_next_month              # 2nd friday next month
        elsif match_ordinal_dayname_monthname
          found_ordinal_dayname_monthname               # 2nd friday december
        end

      elsif match_ordinal_this_month
        found_ordinal_this_month                        # 28th this month
      elsif match_ordinal_next_month
        found_ordinal_next_month                        # 28th next month

      elsif match_first_day
        if match_first_day_this_month
          found_first_day_this_month                    # first day this month
        elsif match_first_day_ofthe_month
            found_first_day_ofthe_month                    # first day this month
        elsif match_first_day_next_month
          found_first_day_next_month                    # first day next month
        elsif match_first_day_monthname
          found_first_day_monthname                     # first day january (well this is stupid, "first day of january" gets preprocessed into "1/1", so what is the point of this?)
        end

      elsif match_first_week
        if match_first_week_this_month
          found_first_week_this_month                    # first day this month
        elsif match_first_week_ofthe_month
          found_first_week_ofthe_month                    # first day next month
        elsif match_first_week_next_month
          found_first_week_next_month                    # first day next month
        elsif match_first_week_monthname
          found_first_week_monthname                     # first day january (well this is stupid, "first day of january" gets preprocessed into "1/1", so what is the point of this?)
        end

      elsif match_last_day                              #sm - I have changed this so that the token is 'thelast'
        if match_last_day_this_month
          found_last_day_this_month
        elsif match_last_day_ofthe_month
          found_last_day_ofthe_month
        elsif match_last_day_next_month
          found_last_day_next_month                     # last day next month
        elsif match_last_day_monthname
          found_last_day_monthname                      # last day november
        end

      elsif match_last_week
        if match_last_week_this_month
          found_last_week_this_month
        elsif match_last_week_ofthe_month
          found_last_week_ofthe_month
        elsif match_last_week_next_month
          found_last_week_next_month                     # last day next month
        elsif match_last_week_monthname
          found_last_week_monthname                      # last day november
        end

      elsif match_at
        if match_at_time
          if match_at_time_through_time
            found_at_time_through_time                  # at 2 through 5pm
          else
            found_at_time                               # at 2
          end
        end

      elsif match_all_day
        found_all_day                                   # all day

      elsif match_tomorrow
#        if match_tomorrow_through
#          if match_tomorrow_through_dayname
#            found_tomorrow_through_dayname              # tomorrow through friday
#          elsif match_tomorrow_through_date
#            found_tomorrow_through_date                 # tomorrow through august 20th
#          end
#        else
          found_tomorrow                                # tomorrow
#        end

      elsif match_now
        if match_now_through
          if match_now_through_dayname
            found_now_through_dayname                   # today through friday
          elsif match_now_through_following_dayname
            found_now_through_following_dayname         # REDUNDANT, PREPROCESS THIS OUT
          elsif match_now_through_date
            found_now_through_date                      # today through 10/1
          elsif match_now_through_monthname
            found_now_through_monthname                 # today through April
          elsif match_now_through_tomorrow
            found_now_through_tomorrow                  # today through tomorrow
          elsif match_now_through_next_dayname
            found_now_through_next_dayname              # today through next friday
          end
        else
          found_now                                     # today
        end

      elsif match_dayname
        if match_dayname_after_date
          found_dayname_after_date
        elsif match_dayname_before_date
          found_dayname_before_date
        elsif match_dayname_the_ordinal
          found_dayname_the_ordinal                     # monday the 21st
        elsif match_dayname_x_weeks_from_next
          found_dayname_x_weeks_from_next               # monday 2 weeks from next
        elsif match_dayname_x_weeks_from_this
          found_dayname_x_weeks_from_this               # monday 2 weeks from this
        elsif match_dayname_after_next
          found dayname_after_next
        else
          found_dayname                                 # monday (also monday tuesday wed...)
        end

      elsif match_monthname
        found_monthname                                 # december (implies 12/1 to 12/31)

      elsif match_through_monthname
          found_through_monthname                         # through december (implies through 11/30)

          # 5th constructor
      # NOTE - TRY TO MAKE WRAPPERS WORK!!!!!

      elsif match_start
        found_start

      elsif match_through
          found_through

      elsif match_time                                  # match time second to last
        if match_time_through_time
          found_time_through_time                       # 10 to 4
        else
          found_time                                    # 10
        end

      elsif match_date                                  # match date last
        if match_date_through_date
          found_date_through_date                       # 5th through the 16th
        else
          found_date                                    # 5th
        end
      end
    end # end def find_constructs


    # this will look for any type 1 wrappers and marry together any adjacent dates into a datespan
    # if there is no prior date, today is assumed
    # if there is no following date, ignore
    def convert_wrapper1_into_date_ranges
      to_delete = []
      wrappers = (@constructs.map.with_index {|c, i| i if c.class.to_s.match('Wrap') && c.wrapper_type == 1}).reject {|c| c.nil?}
        wrappers.each do  |i|
          following = find_following_date(i) if i+1 < @constructs.length
          if following.nil?           ## THIS SHOULDN'T HAPPEN - TYPE 1 WRAPPERS SHOULD ALWAYS BE BOUND TO A DATE
            @constructs.delete_at(i)   ## delete the wrapper
            next                      ## exit the process
          else
            ed = @constructs[following].date
            comp_end = @constructs[following].comp_end
          end
          prior = find_prior_date(i) if i > 0
          if prior.nil?
            sd = @curdate
            comp_start = @constructs[i].comp_start
          else
            sd = @constructs[prior].date
            comp_start = @constructs[prior].comp_start
          end
          # replace the wrapper construct with this datespan
          @constructs[i] = DateSpanConstruct.new(start_date: sd, end_date: ed, comp_start: comp_start, comp_end: comp_end, found_in: __method__)
          # hold a list of date constructs to delete - only delete at end of loop
          if following
            to_delete << following
          end
          if prior
            to_delete << prior
          end
        end
      if to_delete.length > 0       # some date constructs to delete - delete from back to front
        to_delete.sort! { |x,y| y <=> x }
        to_delete.each {|i| @constructs.delete_at(i)}
      end
    end


    def find_prior_date(i)
      return @constructs[0..i-1].rindex {|c| c.class.to_s.match('Date')}
    end

    def find_following_date(i)
      following = @constructs[i+1..@constructs.length - 1].index {|c| c.class.to_s.match('Date')}
      if following
        return following + i + 1
      else
        return following
      end
    end


    # read through @constructs and look at prepositional and conjunctive modifiers to determine
    # how to group dates and times.
    # recurring constructs are like dates

    # type 1 wrappers will have been convereted to datespans - type 2-4 should always be bound to a prior date
    # or a recurrence
    # since they represent a period of time after. e.g. from Easter through the next 3 weeks
    # pair the wrapper to the nearest prior date/recurrence BEFORE pairing with times -
    # ignore the wrappers when pairing dates/recur with times

    def marry_date_time_constructs

      @connector = ''
      @pairing = []
      @orphans = []                   # an array of constructs that are not yet paired
      @wrappers = []                  # date/wrapper or recurrence/wrapper pairs

      # determine whether pairing is necessary
      time_count = @constructs.count {|c| c.class.to_s.match('Time')}
      date_count = @constructs.count {|c| c.class.to_s.match(/(Date|Recu)/)}

      # if no available pairs, just copy over all constructs into a single array
      if date_count == 0 || time_count == 0
        @constructs.each_index {|i| @pairing << i}
        @pair_groups << @pairing
      else
        # first pair wrappers with prior dates/recurrences - if there are multiple prior recurrences,
        # copy the wrapper for each recurrence and pair - this permits separate pairing for times, e.g.
        # 'every monday at 10 or wednesday at 12 for the next 3 weeks'
        wrapper_pairs = []
        @constructs.each_index do |i|
          if @constructs[i].class.to_s.match('Wrap')
            wrapper_pairs = pair_to_wrapper(i)
                if wrapper_pairs.length > 0                 # at least one match found
                  wrapper_pairs << i
                  @wrappers << wrapper_pairs.sort
                end
          end
        end

        # identify all date/time pairs
        # treat each wrapper pair as a single date

        i = 0
        while i < @constructs.length

          end_of_wrapper = this_hasa_wrapper(i)      # returns the last index in the wrapper pairing
          if end_of_wrapper
            this_type = 'Date'
            this_index = end_of_wrapper
          else
            this_type = @constructs[i].class.to_s.match(/(Time|Date|Recu)/).to_s
            this_type == 'Recu' ? (this_type = 'Date') : this_type
            this_index = i
          end

          found_pair = find_pair(this_type, this_index)     # check if next construct pairs to this one
          if found_pair
            while i <= found_pair
              @pairing << i
              i += 1
            end
            @pair_groups << @pairing
            @pairing = []
            i = found_pair
          else
            @orphans << i
          end
          i += 1
        end

        # add orphans to pairs or place in their own pairing
        # orphans always connect to an adjacent pair of the same type, e.g. [Mon or [Tuesday at 4]],
        # but never to a different type, e.g. Mon or [4pm on Tuesday]
        # if both adjacents are of the same type, pair with the prior adjacent,
        # e.g. [[Mon at 2] or 4] or [6 on Tuesday]
        # if no matching type adjacent, place in it's own pairing and insert into pair_group

        # recurring and dateranges should be paired

        #step through each pair group looking for orphans to pair to
        @pair_groups.each do |pairing|
          prior_orphan = find_prior(pairing.first)          # check for any prior orphans
          if prior_orphan                                   # an pairable orphan is found - this is it's index
            pairing.insert(0,@orphans[prior_orphan])        # insert the construct index at the start of the pairing
            @orphans.delete_at(prior_orphan)
            redo                                            # search again for another prior orphan
          end
          following_orphan = find_following(pairing.last)
          if following_orphan
            pairing << @orphans[following_orphan]
            @orphans.delete_at(following_orphan)
            redo
          end
        end

        # any remaining orphans should go into their own pairing - insert into pair_groups in the appropriate location
        @orphans.each do |orphan|
          @pairing = []
          @pairing << orphan
          @pair_groups.insert(insert_spot(orphan), @pairing)
        end
        @orphans = []

        # add today for any time constructs in their own pairing
        @pair_groups.each do |pairing|
          if pairing.count {|p| @constructs[p].class.to_s.match(/(Date|Recu)/)} == 0
            @constructs << DateConstruct.new(date: @curdate, comp_start: 0, comp_end: 0, found_in: __method__)
            pairing << @constructs.length - 1
          end
        end
      end
    end

    def find_pair(type1, index1)

      if index1+2 > @constructs.length
        return nil
      end

      # first check that there are no conjunctions in the components between the constructs
      if found_conjunction(index1, index1+1)
        return nil
      end

      # check to see if the next construct is part of a wrapper pairing
      # if so, treat as a date and decide if the group can be paired to the prior construct
      found_wrapper = this_hasa_wrapper(index1+1)
      if found_wrapper
        return found_wrapper
      end

      # check to see if the next construct pairs
      type2 = @constructs[index1+1].class.to_s.match(/(Time|Date|Recu)/).to_s
      type2 == 'Recu' ? (type2 = 'Date') : type2

      if !(type1 == type2)                                  # a pair is found
        return index1 + 1
      end

      return nil
    end

    def found_conjunction(c1, c2)
      # read all the components between the constructs to see if a conjunction is found
      comp = @constructs[c1].comp_end + 1
      comp_end = @constructs[c2].comp_start

      until comp >= comp_end
        if @components[comp].match(/(\bor\b|\band\b|\,)/)
          return true
        else
          comp += 1
        end
      end
      return false
    end

    def find_prior(pair)       # search for prior orphan that can be paired
      if pair > 0
        type1 = @constructs[pair].class.to_s.match(/(Time|Date|Recu|Wrap)/).to_s
        type1 == 'Recu' || type1 == 'Wrap' ? (type1 = 'Date') : type1
        type2 = @constructs[pair-1].class.to_s.match(/(Time|Date|Recu|Wrap)/).to_s
        type2 == 'Recu' || type2 == 'Wrap' ? (type2 = 'Date') : type2
        if type1 == type2                             # okay to pair if orphaned
          return @orphans.index(pair-1)               # nil if not found
        end
      end
      return nil
    end

  def find_following(pair)       # search for following orphan that can be paired
    if pair+1 < @constructs.length
      type1 = @constructs[pair].class.to_s.match(/(Time|Date|Recu|Wrap)/).to_s
      type1 == 'Recu' || type1 == 'Wrap' ? (type1 = 'Date') : type1
      type2 = @constructs[pair+1].class.to_s.match(/(Time|Date|Recu|Wrap)/).to_s
      type2 == 'Recu' || type2 == 'Wrap' ? (type2 = 'Date') : type2
      if type1 == type2                             # okay to pair if orphaned
        return @orphans.index(pair+1)               # nil if not found
      end
    end
    return nil
  end

  def insert_spot(c_index)
    @pair_groups.each_index do |group_index|
      pairing = @pair_groups[group_index]
      if c_index < pairing.first
        return group_index
      end
    end
    return -1           # insert at end of array
  end

    # return an array of all constructs to bind to this wrapper
    def pair_to_wrapper(wrapper)       # search for prior recurrs or date for wrapper
      pair_array = []
      pair = @constructs[0..wrapper].rindex {|c| c.class.to_s.match(/(Date|Recurrence)Construct/)}
      while pair
        pair_array << pair
        # if a date, join once
        if @constructs[pair].class.to_s.match('Date')         # date
          return pair_array
        else                                                  #recurrence
          if pair>0 && @constructs[pair-1].class.to_s.match(/RecurrenceConstruct/)
            pair -= 1
          else
            pair = nil
          end
        end
      end
      # if there is no recurrence and no date to pair to the wrapper, then if there is a time,
      # create a date occurrence for today and attach to the wrapper, e.g. at 3PM for the next 3 weeks
      if pair_array.length == 0
        pair = @constructs[0..wrapper].rindex {|c| c.class.to_s.match(/'Time'/)}
        if pair
          @constructs.insert(wrapper,DateConstruct.new(date: @curdate, comp_start: 0, comp_end: 0, found_in: __method__))
          pair_array << wrapper - 1
        end
      end
      return pair_array
    end

    def this_hasa_wrapper(index)
      i = 0
      until i+1 > @wrappers.length || @wrappers[i].first  == index
          i += 1
      end
      if i < @wrappers.length
        return @wrappers[i].last
      else
        return nil
      end
    end

    # this creates a NL description of the date times in the constructs
    def build_datetext
      datetext = ''
      last_index = @components.length
      @constructs.each do |construct|
        index = construct.comp_start
        while last_index < index
          if @components[last_index].match(/(\bon\b|\bat\b|\bor\b|\band\b|\,)/)
            datetext << @components[last_index].match(/(\bon\b|\bat\b|\bor\b|\band\b|\,)/).to_s + ' '
          end
          last_index += 1
        end
        last_index = construct.comp_end + 1
        while index < last_index
          datetext << @components[index] + ' '
          index += 1
        end
      end
      return datetext
    end


    def match_every
      @components[@pos] == 'every'
    end


    def match_every_dayname
      @day_index = ZDate.days_of_week.index(@components[@pos + 1])     # if "every [day]"
    end

    # NEED TO BE ABLE TO CATCH 'EVERY WEDNESDAY AT 12 OR THURSDAY AT 5' - THE 'EVERY' IS IMPLIED IN THE SECOND CASE
    # Assume that any following daynames in the sentence will be implied to be recurring as well
    def found_every_dayname
      day_array = [@day_index]
      @constructs << RecurrenceConstruct.new(repeats: :weekly, repeats_on: day_array, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)

      # now see if there is a following implied recurrence and add an "every" component before each that does not
      # already have an "every"
      j = 1
      while @components[@pos + j]
        if ZDate.days_of_week.index(@components[@pos + j]) && !(@components[@pos + j -1] == 'every')
          @components.insert(@pos + j, 'every')
        end
        j += 1
      end
    end

    def match_every_day
      @components[@pos + 1] == 'day'
    end

    def found_every_day
      @constructs << RecurrenceConstruct.new(repeats: :daily, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
    end

    def match_every_other
      @components[@pos + 1] =~ /other|2nd/
    end

    def match_every_other_dayname
      @day_index = ZDate.days_of_week.index(@components[@pos + 2])      # if "every other mon"
    end

    def found_every_other_dayname
      day_array = [@day_index]
      j = 3
      while @components[@pos + j] && ZDate.days_of_week.index(@components[@pos + j])  # if "every other mon tue wed
        day_array << ZDate.days_of_week.index(@components[@pos + j])
        j += 1
      end
      @constructs << RecurrenceConstruct.new(repeats: :altweekly, repeats_on: day_array, comp_start: @pos, comp_end: @pos += (j - 1), found_in: __method__)
    end

    def match_every_other_day
      @components[@pos + 2] == 'day'       #  if "every other day"
    end

    def found_every_other_day
      @constructs << RecurrenceConstruct.new(repeats: :altdaily, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_every_3rd
      @components[@pos + 1] == '3rd'
    end

    def match_every_3rd_dayname
      @day_index = ZDate.days_of_week.index(@components[@pos + 2])      # if "every 3rd tue"
    end

    def found_every_3rd_dayname
      day_array = [@day_index]
      j = 3
      while @components[@pos + j] && ZDate.days_of_week.index(@components[@pos + j])  # if "every 3rd tue wed thu
        day_array << ZDate.days_of_week.index(@components[@pos + j])
        j += 1
      end
      @constructs << RecurrenceConstruct.new(repeats: :threeweekly, repeats_on: day_array, comp_start: @pos, comp_end: @pos += (j - 1), found_in: __method__)
    end

    def match_every_3rd_day
      @components[@pos + 2] == 'day'       #  if "every 3rd day"
    end

    def found_every_3rd_day
      @constructs << RecurrenceConstruct.new(repeats: :threedaily, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_repeats
      @components[@pos] == 'repeats'
    end

    def match_repeats_daily
      @components[@pos + 1] == 'daily'
    end

    def found_repeats_daily
      @constructs << RecurrenceConstruct.new(repeats: :daily, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
    end

    def match_repeats_altdaily
      @components[@pos + 1] == 'altdaily'
    end

    def found_repeats_altdaily
      @constructs << RecurrenceConstruct.new(repeats: :altdaily, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
    end

    def match_repeats_weekly_vague
      @components[@pos + 1] == 'weekly'
    end

    def found_repeats_weekly_vague
      @constructs << RecurrenceConstruct.new(repeats: :weekly, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
    end

    def match_repeats_altweekly_vague
      @components[@pos + 1] == 'altweekly'
    end

    def found_repeats_altweekly_vague
      @constructs << RecurrenceConstruct.new(repeats: :altweekly, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
    end

    def match_repeats_monthly
      @components[@pos + 1] == 'monthly'
    end

    def match_repeats_daymonthly
      @components[@pos + 2] && @components[@pos + 3] && (@week_num = @components[@pos + 2].to_i) && @week_num > 0 && @week_num <= 5 && (@day_index = ZDate.days_of_week.index(@components[@pos + 3]))   # "repeats monthly 2nd wed"
    end

    def found_repeats_daymonthly
      rep_array = [[@week_num, @day_index]]     # That is NOT a typo, not sure what I meant by that! maybe the nested array
      j = 4
      while @components[@pos + j] && @components[@pos + j + 1] && (@week_num = @components[@pos + j].to_i) && @week_num > 0 && @week_num <= 5 && (@day_index = ZDate.days_of_week.index(@components[@pos + j + 1]))
        rep_array << [@week_num, @day_index]
        j += 2
      end
      @constructs << RecurrenceConstruct.new(repeats: :daymonthly, repeats_on: rep_array, comp_start: @pos, comp_end: @pos += (j - 1), found_in: __method__)
    end

    def match_repeats_datemonthly
      @components[@pos + 2] && ConstructFinder.ordinal_only?(@components[@pos + 2]) && @date_array = [@components[@pos + 2].to_i]   # repeats monthly 22nd
    end

    def found_repeats_datemonthly
      j = 3
      while @components[@pos + j] && ConstructFinder.ordinal_only?(@components[@pos + j])
        @date_array << @components[@pos + j].to_i
        j += 1
      end
      @constructs << RecurrenceConstruct.new(repeats: :datemonthly, repeats_on: @date_array, comp_start: @pos, comp_end: @pos += (j - 1), found_in: __method__)
    end

    def match_repeats_altmonthly
      @components[@pos + 1] == 'altmonthly'
    end

    def match_repeats_altmonthly_daymonthly
      @components[@pos + 2] && @components[@pos + 3] && (@week_num = @components[@pos + 2].to_i) && @week_num > 0 && @week_num <= 5 && (@day_index = ZDate.days_of_week.index(@components[@pos + 3]))   # "repeats altmonthly 2nd wed"
    end

    def found_repeats_altmonthly_daymonthly
      rep_array = [[@week_num, @day_index]]
      j = 4
      while @components[@pos + j] && @components[@pos + j + 1] && (@week_num = @components[@pos + j].to_i) && @week_num > 0 && @week_num <= 5 && (@day_index = ZDate.days_of_week.index(@components[@pos + j + 1]))
        rep_array << [@week_num, @day_index]
        j += 2
      end
      @constructs << RecurrenceConstruct.new(repeats: :altdaymonthly, repeats_on: rep_array, comp_start: @pos, comp_end: @pos += (j - 1), found_in: __method__)
    end

    def match_repeats_altmonthly_datemonthly
      @components[@pos + 2] && ConstructFinder.ordinal_only?(@components[@pos + 2]) && @date_array = [@components[@pos + 2].to_i]   # repeats altmonthly 22nd
    end

    def found_repeats_altmonthly_datemonthly
      j = 3
      while @components[@pos + j] && ConstructFinder.ordinal_only?(@components[@pos + j])
        @date_array << @components[@pos + j].to_i
        j += 1
      end
      @constructs << RecurrenceConstruct.new(repeats: :altdatemonthly, repeats_on: @date_array, comp_start: @pos, comp_end: @pos += (j - 1), found_in: __method__)
    end

    def match_repeats_threemonthly
      @components[@pos + 1] == 'threemonthly'
    end

    def match_repeats_threemonthly_daymonthly
      @components[@pos + 2] && @components[@pos + 3] && (@week_num = @components[@pos + 2].to_i) && @week_num > 0 && @week_num <= 5 && (@day_index = ZDate.days_of_week.index(@components[@pos + 3]))   # "repeats threemonthly 2nd wed"
    end

    def found_repeats_threemonthly_daymonthly
      rep_array = [[@week_num, @day_index]]     # That is NOT a typo
      j = 4
      while @components[@pos + j] && @components[@pos + j + 1] && (@week_num = @components[@pos + j].to_i) && @week_num > 0 && @week_num <= 5 && (@day_index = ZDate.days_of_week.index(@components[@pos + j + 1]))
        rep_array << [@week_num, @day_index]
        j += 2
      end
      @constructs << RecurrenceConstruct.new(repeats: :threedaymonthly, repeats_on: rep_array, comp_start: @pos, comp_end: @pos += (j - 1), found_in: __method__)
    end

    def match_repeats_threemonthly_datemonthly
      @components[@pos + 2] && ConstructFinder.ordinal_only?(@components[@pos + 2]) && @date_array = [@components[@pos + 2].to_i]   # repeats threemonthly 22nd
    end

    def found_repeats_threemonthly_datemonthly
      j = 3
      while @components[@pos + j] && ConstructFinder.ordinal_only?(@components[@pos + j])
        @date_array << @components[@pos + j].to_i
        j += 1
      end
      @constructs << RecurrenceConstruct.new(repeats: :threedatemonthly, repeats_on: @date_array, comp_start: @pos, comp_end: @pos += (j - 1), found_in: __method__)
    end

    def match_for_x
      @components[@pos] == 'for' && ConstructFinder.digits_only?(@components[@pos + 1]) && @length = @components[@pos + 1].to_i
    end

    def match_for_x_days
      @components[@pos + 2] =~ /days?/
    end

    def found_for_x_days
      @constructs << WrapperConstruct.new(wrapper_type: 2, wrapper_length: @length, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_for_x_weeks
      @components[@pos + 2] =~ /weeks?/
    end

    def found_for_x_weeks
      @constructs << WrapperConstruct.new(wrapper_type: 3, wrapper_length: @length, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_for_x_months
      @components[@pos + 2] =~ /months?/
    end

    def found_for_x_months
      @constructs << WrapperConstruct.new(wrapper_type: 4, wrapper_length: @length, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    #sm - I have added all of the previous methods since the program was not trapping for this but there is logic in zdate
    # for handling prior dates/days/weeks/months
    def match_previous
      @components[@pos] == 'previous'
    end

    def match_previous_weekend
      @components[@pos + 1] == 'weekend'   # "previous weekend"
    end

    def found_previous_weekend
      dsc = DateSpanConstruct.new(start_date: @curdate.prev(5), comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
      dsc.end_date = dsc.start_date.add_days(1)
      @constructs << dsc
    end

    def match_previous_dayname
      @day_index = ZDate.days_of_week.index(@components[@pos + 1])  # if "previous [day]"
    end

    def found_previous_dayname
      day_to_add = @curdate.prev(@day_index)
      @constructs << DateConstruct.new(date: day_to_add, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
      while @components[@pos + 1] && @day_index = ZDate.days_of_week.index(@components[@pos + 1])
        # note @pos gets incremented on each pass
        @constructs << DateConstruct.new(date: day_to_add = day_to_add.this(@day_index), comp_start: @pos + 1, comp_end: @pos += 1, found_in: __method__)
      end
    end

    def match_previous_x
      @components[@pos + 1] && ConstructFinder.digits_only?(@components[@pos + 1]) && @length = @components[@pos + 1].to_i
    end

    def match_previous_x_days
      @components[@pos + 2] =~ /days?/                              # "previous x days"
    end

    def found_previous_x_days
      @constructs << DateSpanConstruct.new(start_date: @curdate, end_date: @curdate.add_days(-1 * @length), comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_previous_x_weeks
      @components[@pos + 2] =~ /weeks?/                             # "previous x weeks"
    end

    def found_previous_x_weeks
      @constructs << DateSpanConstruct.new(start_date: @curdate, end_date: @curdate.add_weeks(-1 * @length), comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_previous_x_months
      @components[@pos + 2] =~ /months?/                             # "previous x months"
    end

    def found_previous_x_months
      @constructs << DateSpanConstruct.new(start_date: @curdate, end_date: @curdate.add_months(-1 * @length), comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_previous_x_years
      @components[@pos + 2] =~ /years?/                          # "previous x years"
    end

    def found_previous_x_years
      @constructs << DateSpanConstruct.new(start_date: @curdate, end_date: @curdate.add_years(-1 * @length), comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_previous_week
      @components[@pos + 1] =~ /weeks?/
    end

    def found_previous_week
      sd = @curdate.prev(0)
      ed = sd.add_days(6)
      @constructs << DateSpanConstruct.new(start_date: sd, end_date: ed, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
    end

    def match_previous_month
      @components[@pos + 1] =~ /months?/
    end

    def found_previous_month
      sd = @curdate.add_months(-1).beginning_of_month
      ed = sd.end_of_month
      @constructs << DateSpanConstruct.new(start_date: sd, end_date: ed, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
    end
#sm -----------------------------------------------------------------

    def match_this
      @components[@pos] == 'this'
    end

    def match_thiscoming
      @components[@pos] == 'thiscoming'
    end

    def match_thiscoming_dayname
      @day_index = ZDate.days_of_week.index(@components[@pos + 1])
    end

    def found_thiscoming_dayname
      @week_index = 0
      day_to_add = @curdate.thiscoming(@day_index)
      @constructs << DateConstruct.new(date: day_to_add, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
      while @components[@pos + 1] && @day_index = ZDate.days_of_week.index(@components[@pos + 1])
        # note @pos gets incremented on each pass
        @constructs << DateConstruct.new(date: day_to_add = day_to_add.thiscoming(@day_index), comp_start: @pos + 1, comp_end: @pos += 1, found_in: __method__)
      end
    end

    def match_this_dayname
      @day_index = ZDate.days_of_week.index(@components[@pos + 1])
    end

    def found_this_dayname
      @week_index = 0
      day_to_add = @curdate.this(@day_index)
      @constructs << DateConstruct.new(date: day_to_add, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
      while @components[@pos + 1] && @day_index = ZDate.days_of_week.index(@components[@pos + 1])
        # note @pos gets incremented on each pass
        @constructs << DateConstruct.new(date: day_to_add = day_to_add.this(@day_index), comp_start: @pos + 1, comp_end: @pos += 1, found_in: __method__)
      end
    end

    def match_this_week
      @components[@pos + 1] =~ /weeks?/
    end

    def found_this_week
      # search for following dayname
      j = 2
      until @components[@pos + j].nil? || @day_index = ZDate.days_of_week.index(@components[@pos + j]) || @components[@pos + j].match(/(\bor\b|\band\b|\,)/)
        j += 1
      end
      if @components[@pos + j].nil? || @components[@pos + j].match(/(\bor\b|\band\b|\,)/)       # nothing found
        if @curdate.dayindex >3 ## if it's Friday-Sunday, assume he means next week
          sd = @curdate.next(0)
          ed = sd.add_days(6)
        else
          sd = @curdate
          ed = @curdate.this(6)
        end
        @constructs << DateSpanConstruct.new(start_date: sd, end_date: ed, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
      else                                          # dayname found - remove week reference and add 'next' for each dayname to pair
        @components.delete_at(@pos)                 # remove 'this'
        @components.delete_at(@pos + 1)             # remove 'week'
        @pos -= 1
        @week_index = 0
      end
    end

    def match_this_month
      @components[@pos + 1] =~ /months?/
    end

    def found_this_month
      @constructs << DateSpanConstruct.new(start_date: @curdate, end_date: @curdate.end_of_month, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
    end

    def match_next
      @components[@pos] == 'next'
    end

    def match_next_weekend
      @components[@pos + 1] == 'weekend'   # "next weekend"
    end

    def found_next_weekend
      dsc = DateSpanConstruct.new(start_date: @curdate.next(5), comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
      dsc.end_date = dsc.start_date.add_days(1)
      @constructs << dsc
    end

    def match_next_dayname
      @day_index = ZDate.days_of_week.index(@components[@pos + 1])  # if "next [dayname]"
    end

    def found_next_dayname
      @week_index = 1
      day_to_add = @curdate.x_weeks_from_day(@week_index, @day_index)
      @constructs << DateConstruct.new(date: day_to_add, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
      while @components[@pos + 1] && @day_index = ZDate.days_of_week.index(@components[@pos + 1])
        # note @pos gets incremented on each pass
        @constructs << DateConstruct.new(date: day_to_add = day_to_add.this(@day_index), comp_start: @pos + 1, comp_end: @pos += 1, found_in: __method__)
      end
    end

    def match_next_x
      @components[@pos + 1] && ConstructFinder.digits_only?(@components[@pos + 1]) && @length = @components[@pos + 1].to_i
    end

    def match_next_x_days
      @components[@pos + 2] =~ /days?/                              # "next x days"
    end

    def found_next_x_days
      @constructs << DateSpanConstruct.new(start_date: @curdate, end_date: @curdate.add_days(@length), comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_next_x_weeks
      @components[@pos + 2] =~ /weeks?/                             # "next x weeks"
    end

    def found_next_x_weeks
      @constructs << DateSpanConstruct.new(start_date: @curdate, end_date: @curdate.add_weeks(@length), comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_next_x_months
      @components[@pos + 2] =~ /months?/                             # "next x months"
    end

    def found_next_x_months
      @constructs << DateSpanConstruct.new(start_date: @curdate, end_date: @curdate.add_months(@length), comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_next_x_years
      @components[@pos + 2] =~ /years?/                          # "next x years"
    end

    def found_next_x_years
      @constructs << DateSpanConstruct.new(start_date: @curdate, end_date: @curdate.add_years(@length), comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_next_week
      @components[@pos + 1] =~ /weeks?/
    end

    # check for patterns of next week + dayname if there is no conjunction between week
    # and the dayname. this translates to next + dayname
    def found_next_week
      # search for following dayname
      j = 2
      until @components[@pos + j].nil? || @day_index = ZDate.days_of_week.index(@components[@pos + j]) || @components[@pos + j].match(/(\bor\b|\band\b|\,)/)
        j += 1
      end
      if @components[@pos + j].nil? || @components[@pos + j].match(/(\bor\b|\band\b|\,)/)       # nothing found
        sd = @curdate.next(0)
        ed = sd.add_days(6)               # sm - changed add_days to 6 from 7 - the week ends on Sunday, not Monday
        @constructs << DateSpanConstruct.new(start_date: sd, end_date: ed, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
      else                                          # dayname found - remove week reference and add 'next' for each dayname to pair
        @components.delete_at(@pos)                 # remove 'next'
        @components.delete_at(@pos + 1)             # remove 'week'
        @pos -= 1
        @week_index = 1
      end
    end


    def match_the_following_week
      @components[@pos] == 'thefollowingweek'
    end

    # the week depends on a prior date reference, e.g. 'next Monday or the following week'
    # so we need to check the prior date construct as a reference
    def found_the_following_week
      i = @constructs.rindex {|c| c.class.to_s.match('Date')}
      if i
        if @constructs[i].class.to_s.match('DateSpan')
          if @constructs[i].end_date
            prior_date = @constructs[i].end_date
          else
            prior_date = @constructs[i].start_date
          end
        else
          prior_date = @constructs[i].date
        end
      else
        prior_date = @curdate
      end
      sd = prior_date.next(0)
      ed = sd.add_days(6)
      @constructs << DateSpanConstruct.new(start_date: sd, end_date: ed, comp_start: @pos, comp_end: @pos, found_in: __method__)
    end

    def match_the_following_month
      @components[@pos] == 'thefollowingmonth'
    end

    # the month depends on a prior date reference, e.g. 'every wed this month or monday the following month'
    # so we need to check the prior date construct as a reference
    def found_the_following_month
      i = @constructs.rindex {|c| c.class.to_s.match('Date')}
      if i
        if @constructs[i].class.to_s.match('DateSpan')
          if @constructs[i].end_date
            prior_date = @constructs[i].end_date
          else
            prior_date = @constructs[i].start_date
          end
        else
          prior_date = @constructs[i].date
        end
      else
        prior_date = @curdate
      end
      sd = prior_date.beginning_of_next_month
      ed = sd.end_of_month
      @constructs << DateSpanConstruct.new(start_date: sd, end_date: ed, comp_start: @pos, comp_end: @pos, found_in: __method__)
    end

    def match_week_after_next
      @components[@pos] == 'theweekafternext'
    end

    def found_week_after_next
      # search for following dayname
      j = 1
      until @components[@pos + j].nil? || @day_index = ZDate.days_of_week.index(@components[@pos + j]) || @components[@pos + j].match(/(\bor\b|\band\b|\,)/)
        j += 1
      end
      if @components[@pos + j].nil? || @components[@pos + j].match(/(\bor\b|\band\b|\,)/)       # nothing found
        sd = @curdate.x_weeks_from_day(2,0)
        ed = sd.add_days(6)
        @constructs << DateSpanConstruct.new(start_date: sd, end_date: ed, comp_start: @pos, comp_end: @pos, found_in: __method__)
      else                                          # dayname found - remove week reference and add 'next' for each dayname to pair
        @components.delete_at(@pos)                 # remove 'theweekafternex'
        @week_index = 2
      end
    end

# sm -------------------------
    def match_thedayafter
      @components[@pos] == 'thedayafter'
    end

    def match_thedayafter_tomorrow
      @components[@pos + 1] == 'tomorrow'
    end

    def found_thedayafter_tomorrow
      @constructs << DateConstruct.new(date: @curdate.add_days(2), comp_start: @pos, comp_end: @pos +=1, found_in: __method__)
    end

    def match_thedayafter_date
      @date1 = ZDate.interpret(@components[@pos + 1], @curdate)
    end

    def found_thedayafter_date
      @constructs << DateConstruct.new(date: @date1.add_days(1), comp_start: @pos, comp_end: @pos +=1, found_in: __method__)
    end

    def match_thedaybefore
      @components[@pos] == 'thedaybefore'
    end

    def match_thedaybefore_date
      @date1 = ZDate.interpret(@components[@pos + 1], @curdate)
    end

    def found_thedaybefore_date
      @constructs << DateConstruct.new(date: @date1.add_days(-1), comp_start: @pos, comp_end: @pos +=1, found_in: __method__)
    end


    def match_theweekafter
      @components[@pos] == 'theweekafter'
    end

    def match_theweekafter_date
      @date1 = ZDate.interpret(@components[@pos + 1], @curdate)
    end

    def found_theweekafter_date
      sd = @date1.add_days((7 - @date1.dayindex) % 7)
      ed = sd.add_days(6)
      @constructs << DateSpanConstruct.new(start_date: sd, end_date: ed, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
    end

    def match_theweekbefore
      @components[@pos] == 'theweekbefore'
    end

    def match_theweekbefore_date
      @date1 = ZDate.interpret(@components[@pos + 1], @curdate)
    end

    def found_theweekbefore_date
      sd = @date1.add_days(-(((@date1.dayindex+2) % 7) + 5))
      ed = sd.add_days(6)
      @constructs << DateSpanConstruct.new(start_date: sd, end_date: ed, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
    end

    def match_next_month
      # note it is important that all other uses of "next month" come after indicating words such as "every day next month"; otherwise they will be converted here
      @components[@pos + 1] =~ /months?/
    end

    def found_next_month
      @sd = @curdate.add_months(1).beginning_of_month
      @ed = @sd.end_of_month
      @constructs << DateSpanConstruct.new(start_date: @sd, end_date: @ed, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
    end

    def match_week
      @components[@pos] == 'week'
    end

    def match_nth_week_of_month
      @components[@pos] =~ /(1st|2nd|3rd|4th|5th)/ && @components[@pos + 1] == 'week' && @components[@pos + 2] == 'of' && (@month_index = ZDate.months_of_year.index(@components[@pos + 3]))
    end

    def found_nth_week_of_month
      @sd = @curdate.jump_to_month(@month_index + 1).ordinal_dayindex(@components[@pos].to_i, 0)
      @ed = @sd.add_days(6)
      @constructs << DateSpanConstruct.new(start_date: @sd, end_date: @ed, comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_week_of_date
      @components[@pos + 1] == 'of' && @date1 = ZDate.interpret(@components[@pos + 2], @curdate)
    end

    def found_week_of_date      # sm - modify to represent a week starting on Monday
      @sd = @date1.add_days(- @date1.dayindex)
      @ed = @sd.add_days(6)
      @constructs << DateSpanConstruct.new(start_date: @sd, end_date: @ed, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_week_through_date
      @components[@pos + 1] == 'through' && @date1 = ZDate.interpret(@components[@pos + 2], @curdate)
    end

    def found_week_through_date
      @constructs << DateSpanConstruct.new(start_date: @date1.sub_days(6), end_date: @date1, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_x_weeks_from
      ConstructFinder.digits_only?(@components[@pos]) && @components[@pos + 1] =~ /^weeks?$/ && @components[@pos + 2] == 'from' && @length = @components[@pos].to_i      # if "x weeks from"
    end

    def match_x_weeks_from_dayname
      @day_index = ZDate.days_of_week.index(@components[@pos + 3])   # if "x weeks from monday"
    end

    def found_x_weeks_from_dayname
      @constructs << DateConstruct.new(date: @curdate.x_weeks_from_day(@length, @day_index), comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    # Reduntant, preprocess out!
    def match_x_weeks_from_this_dayname
      @components[@pos + 3] == 'this' && @day_index = ZDate.days_of_week.index(@components[@pos + 4])           # if "x weeks from this monday"
    end

    # Reduntant, preprocess out!
    def found_x_weeks_from_this_dayname
      # this is the exact some construct as found_x_weeks_from_dayname, just position and comp_end has to increment by 1 more; pretty stupid, this should be caught in preprocessing
      @constructs << DateConstruct.new(date: @curdate.x_weeks_from_day(@length, @day_index), comp_start: @pos, comp_end: @pos += 4, found_in: __method__)
    end

    def match_x_weeks_from_next_dayname
      @components[@pos + 3] == 'next' && @day_index = ZDate.days_of_week.index(@components[@pos + 4])   # if "x weeks from next monday"
    end

    def found_x_weeks_from_next_dayname
      @constructs << DateConstruct.new(date: @curdate.x_weeks_from_day(@length + 1, @day_index), comp_start: @pos, comp_end: @pos += 4, found_in: __method__)
    end

    def match_x_weeks_from_tomorrow
      @components[@pos + 3] == 'tomorrow'       # if "x weeks from tomorrow"
    end

    def found_x_weeks_from_tomorrow
      @constructs << DateConstruct.new(date: @curdate.add_days(1).add_weeks(@length), comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_x_weeks_from_now
      @components[@pos + 3] =~ /\b(today)|(now)\b/    # if "x weeks from today"
    end

    def found_x_weeks_from_now
      @constructs << DateConstruct.new(date: @curdate.x_weeks_from_day(@length, @curdate.dayindex), comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_x_weeks_from_yesterday
      @components[@pos + 3] == 'yesterday'    # "x weeks from yesterday"
    end

    def found_x_weeks_from_yesterday
      @constructs << DateConstruct.new(date: @curdate.sub_days(1).add_weeks(@length), comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_x_months_from
      ConstructFinder.digits_only?(@components[@pos]) && @components[@pos + 1] =~ /^months?$/ && @components[@pos + 2] == 'from' && @length = @components[@pos].to_i       # if "x months from"
    end

    def match_x_months_from_dayname
      @day_index = ZDate.days_of_week.index(@components[@pos + 3])                                             # if "x months from monday"
    end

    def found_x_months_from_dayname
      @constructs << DateConstruct.new(date: @curdate.this(@day_index).add_months(@length), comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_x_months_from_this_dayname
      @components[@pos + 3] == 'this' && @day_index = ZDate.days_of_week.index(@components[@pos + 4])            # if "x months from this monday"
    end

    def found_x_months_from_this_dayname
      @constructs << DateConstruct.new(date: @curdate.this(@day_index).add_months(@length), comp_start: @pos, comp_end: @pos += 4, found_in: __method__)
    end

    def match_x_months_from_next_dayname
      @components[@pos + 3] == 'next' && @day_index = ZDate.days_of_week.index(@components[@pos + 4])            # if "x months from next monday"
    end

    def found_x_months_from_next_dayname
      @constructs << DateConstruct.new(date: @curdate.next(@day_index).add_months(@length), comp_start: @pos, comp_end: @pos += 4, found_in: __method__)
    end

    def match_x_months_from_tomorrow
      @components[@pos + 3] == 'tomorrow'       # if "x months from tomorrow"
    end

    def found_x_months_from_tomorrow
      @constructs << DateConstruct.new(date: @curdate.add_days(1).add_months(@length), comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_x_months_from_now
      @components[@pos + 3] =~ /\b(today)|(now)\b/    # if "x months from today"
    end

    def found_x_months_from_now
      @constructs << DateConstruct.new(date: @curdate.add_months(@length), comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_x_months_from_yesterday
      @components[@pos + 3] == 'yesterday'    # "x months from yesterday"
    end

    def found_x_months_from_yesterday
      @constructs << DateConstruct.new(date: @curdate.sub_days(1).add_months(@length), comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_x_days_from
      ConstructFinder.digits_only?(@components[@pos]) && @components[@pos + 1] =~ /^days?$/ && @components[@pos + 2] == 'from' && @length = @components[@pos].to_i     # 3 days from
    end

    def match_x_days_from_now
      @components[@pos + 3] =~ /\b(now)|(today)\b/           # 3 days from today; 3 days from now
    end

    def found_x_days_from_now
      @constructs << DateConstruct.new(date: @curdate.add_days(@length), comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_x_days_from_dayname
      @day_index = ZDate.days_of_week.index(@components[@pos + 3])    # 3 days from monday, why would someone do this?
    end

    def found_x_days_from_dayname
      @constructs << DateConstruct.new(date: @curdate.this(@day_index).add_days(@length), comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_x_dayname_from
      ConstructFinder.digits_only?(@components[@pos]) && (@day_index = ZDate.days_of_week.index(@components[@pos + 1])) && @components[@pos + 2] == 'from' && @length = @components[@pos].to_i    # "2 tuesdays from"
    end

    def match_x_dayname_from_now
      @components[@pos + 3] =~ /\b(today)|(now)\b/     # if "2 tuesdays from now"
    end

    def found_x_dayname_from_now
      # this isn't exactly intuitive.  If someone says "two tuesday from now" and it is tuesday, they mean "in two weeks."  If it is not tuesday, they mean "next tuesday"
      @constructs << DateConstruct.new(date: @curdate.x_weeks_from_day(@length,@day_index), comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_x_dayname_from_tomorrow
      @components[@pos + 3] == 'tomorrow'
    end

    def found_x_dayname_from_tomorrow
      # If someone says "two tuesday from tomorrow" and tomorrow is tuesday, they mean "two weeks from tomorrow."  If it is not tuesday, this person does not make sense, but we can interpet it as "next tuesday"
      tomorrow_index = (@curdate.dayindex + 1) % 7
      d = (@days_index == tomorrow_index) ? @curdate.add_days(1).add_weeks(@length) : @curdate.x_weeks_from_day(@length - 1, @day_index)
      @constructs << DateConstruct.new(date: d, comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_x_dayname_from_yesterday
      @components[@pos + 3] == 'yesterday'
    end

    def found_x_dayname_from_yesterday
      # If someone says "two tuesday from yesterday" and yesterday was tuesday, they mean "two weeks from yesterday."  If it is not tuesday, this person does not make sense, but we can interpet it as "next tuesday"
      yesterday_index = (@curdate.dayindex == 0 ? 6 : @curdate.dayindex - 1)
      d = (@days_index == yesterday_index) ? @curdate.sub_days(1).add_weeks(@length) : @curdate.x_weeks_from_day(@length - 1, @day_index)
      @constructs << DateConstruct.new(date: d, comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_x_dayname_from_this
      @components[@pos + 3] == 'this'    #  "two tuesdays from this"
    end

    def found_x_dayname_from_this
      dc = DateConstruct.new(date: @curdate.this(@day_index).add_weeks(@length), comp_start: @pos, found_in: __method__)
      if @components[@post + 4] == 'one' || ZDate.days_of_week.index(@components[@pos + 4])    # talk about redundant (2 tuesdays from this one, 2 tuesdays from this tuesday)
        dc.comp_end = @pos += 4
      else
        dc.comp_end = @pos += 3
      end
      @constructs << dc
    end

    def match_x_dayname_from_next
      @components[@pos + 3] == 'next'    #  "two tuesdays from next"
    end

    def found_x_dayname_from_next
      dc = DateConstruct.new(date: @curdate.next(@day_index).add_weeks(@length), comp_start: @pos, found_in: __method__)
      if @components[@post + 4] == 'one' || ZDate.days_of_week.index(@components[@pos + 4])    # talk about redundant (2 tuesdays from next one, 2 tuesdays from next tuesday)
        dc.comp_end = @pos += 4
      else
        dc.comp_end = @pos += 3
      end
      @constructs << dc
    end

    def match_x_minutes_from_now
      ConstructFinder.digits_only?(@components[@pos]) && @components[@pos + 1] =~ /minutes?/ && @components[@pos + 2] == 'from' && @components[@pos + 3] =~ /^(today|now)$/ && @length = @components[@pos].to_i
    end

    def found_x_minutes_from_now
      date = nil  # define out of scope of block
      time = @curtime.add_minutes(@length) { |days_to_increment| date = @curdate.add_days(days_to_increment) }
      @constructs << DateConstruct.new(date: date, comp_start: @pos, comp_end: @pos + 4, found_in: __method__)
      @constructs << TimeConstruct.new(time: time, comp_start: @pos, comp_end: @pos += 4, found_in: __method__)
    end

    def match_x_hours_from_now
      ConstructFinder.digits_only?(@components[@pos]) && @components[@pos + 1] =~ /hours?/ && @components[@pos + 2] == 'from' && @components[@pos + 3] =~ /^(today|now)$/ && @length = @components[@pos].to_i
    end

    def found_x_hours_from_now
      date = nil
      time = @curtime.add_hours(@length) { |days_to_increment| date = @curdate.add_days(days_to_increment) }
      @constructs << DateConstruct.new(date: date, comp_start: @pos, comp_end: @pos + 4, found_in: __method__)
      @constructs << TimeConstruct.new(time: time, comp_start: @pos, comp_end: @pos += 4, found_in: __method__)
    end



    def match_ordinal_dayname
      @components[@pos] =~ /(1st|2nd|3rd|4th|5th)/ && (@day_index = ZDate.days_of_week.index(@components[@pos + 1])) && @week_num = @components[@pos].to_i     # last saturday
    end

    def match_ordinal_dayname_this_month
      @components[@pos + 2] == 'this' && @components[@pos + 3] == 'month'                  # last saturday this month
    end

    def found_ordinal_dayname_this_month
      @constructs << DateConstruct.new(date: @curdate.ordinal_dayindex(@week_num, @day_index), comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_ordinal_dayname_next_month
      @components[@pos + 2] == 'next' && @components[@pos + 3] == 'month'        # 1st monday next month
    end

    def found_ordinal_dayname_next_month
      @constructs << DateConstruct.new(date: @curdate.add_months(1).ordinal_dayindex(@week_num, @day_index), comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_ordinal_dayname_monthname
      @month_index = ZDate.months_of_year.index(@components[@pos + 2])         # second friday december
    end

    def found_ordinal_dayname_monthname
      @constructs << DateConstruct.new(date: @curdate.jump_to_month(@month_index + 1).ordinal_dayindex(@week_num, @day_index), comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_ordinal_this_month
      @components[@pos] =~ /(0?[1-9]|[12][0-9]|3[01])(st|nd|rd|th)/ && @components[@pos + 1] == 'this' && @components[@pos + 2] = 'month' && @length = @components[@pos].to_i      # 28th this month
    end

    def match_ordinal_next_month
      @components[@pos] =~ /(0?[1-9]|[12][0-9]|3[01])(st|nd|rd|th)/ && @components[@pos + 1] == 'next' && @components[@pos + 2] = 'month' && @length = @components[@pos].to_i      # 28th next month
    end

    def found_ordinal_this_month
      if @curdate.day > @length
        # e.g. it is the 30th of the month and a user types "1st of the month", they mean "first of next month"
        date = @curdate.add_months(1).beginning_of_month.add_days(@length - 1)
      else
        date = @curdate.beginning_of_month.add_days(@length - 1)
      end
      @constructs << DateConstruct.new(date: date, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def found_ordinal_next_month
      @constructs << DateConstruct.new(date: @curdate.add_months(1).beginning_of_month.add_days(@length - 1), comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_first_day
      @components[@pos] == '1st' && @components[@pos + 1] == 'day'     # 1st day
    end

    def match_first_day_this_month
      @components[@pos + 2] == 'this' && @components[@pos + 3] == 'month'                  # 1st day this month
    end

    def found_first_day_this_month
      @constructs << DateConstruct.new(date: @curdate.beginning_of_month, comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_first_day_ofthe_month
      @components[@pos + 2] == 'of' && @components[@pos + 3] == 'the' && @components[@pos + 4] == 'month'                  # 1st day this month
    end

    def found_first_day_ofthe_month
      @constructs << DateConstruct.new(date: @curdate.beginning_of_month, comp_start: @pos, comp_end: @pos += 4, found_in: __method__)
    end

    def match_first_day_next_month
      @components[@pos + 2] == 'next' && @components[@pos + 3] == 'month'        # 1st day next month
    end

    def found_first_day_next_month
      @constructs << DateConstruct.new(date: @curdate.add_months(1).beginning_of_month, comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_first_day_monthname
      @month_index = ZDate.months_of_year.index(@components[@pos + 2])         # 1st day december
    end

    def found_first_day_monthname
      @constructs << DateConstruct.new(date: @curdate.jump_to_month(@month_index + 1), comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_first_week
      @components[@pos] == '1st' && @components[@pos + 1] == 'week'
    end

    def match_first_week_this_month
      @components[@pos + 2] == 'this' && @components[@pos + 3] == 'month'                  # 1st day this month
    end

    def found_first_week_this_month
      @sd = @curdate.beginning_of_month
      @ed = @sd.add_days(6)
      @constructs << DateSpanConstruct.new(start_date: @sd, end_date: @ed, comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_first_week_ofthe_month
      @components[@pos + 2] == 'of' && @components[@pos + 3] == 'the' && @components[@pos + 4] == 'month'                  # 1st day this month
    end

    def found_first_week_ofthe_month
      @sd = @curdate.beginning_of_month
      @ed = @sd.add_days(6)
      @constructs << DateSpanConstruct.new(start_date: @sd, end_date: @ed, comp_start: @pos, comp_end: @pos += 4, found_in: __method__)
    end

    def match_first_week_next_month
      @components[@pos + 2] == 'next' && @components[@pos + 3] == 'month'        # 1st day next month
    end

    def found_first_week_next_month
      @sd = @curdate.add_months(1).beginning_of_month
      @ed = @sd.add_days(6)
      @constructs << DateSpanConstruct.new(start_date: @sd, end_date: @ed, comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_first_week_monthname
      @components[@pos + 2] =~ /(in|of)/ && @month_index = ZDate.months_of_year.index(@components[@pos + 3])
    end

    def found_first_week_monthname
      @sd = @curdate.jump_to_month(@month_index + 1).beginning_of_month
      @ed = @sd.add_days(6)
      @constructs << DateSpanConstruct.new(start_date: @sd, end_date: @ed, comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_last_day
      @components[@pos] == 'thelast' && @components[@pos + 1] == 'day'     # last day - sm- changed to thelast
    end

    def match_last_day_this_month
      @components[@pos + 2] == 'this' && @components[@pos + 3] == 'month'
    end

    def found_last_day_this_month
      @constructs << DateConstruct.new(date: @curdate.end_of_month, comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_last_day_ofthe_month
      @components[@pos + 2] == 'of' && @components[@pos + 3] == 'the' && @components[@pos + 4] == 'month'
    end

    def found_last_day_ofthe_month
      @constructs << DateConstruct.new(date: @curdate.end_of_month, comp_start: @pos, comp_end: @pos += 4, found_in: __method__)
    end

    def match_last_day_next_month
      @components[@pos + 2] == 'next' && @components[@pos + 3] == 'month'        # 1st day next month
    end

    def found_last_day_next_month
      @constructs << DateConstruct.new(date: @curdate.add_months(1).end_of_month, comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_last_day_monthname
      @month_index = ZDate.months_of_year.index(@components[@pos + 2])         # 1st day december
    end

    def found_last_day_monthname
      @constructs << DateConstruct.new(date: @curdate.jump_to_month(@month_index + 1).end_of_month, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_last_week
      @components[@pos] == 'thelast' && @components[@pos + 1] == 'week'
    end

    def match_last_week_this_month
      @components[@pos + 2] == 'this' && @components[@pos + 3] == 'month'                  # 1st day this month
    end

    def found_last_week_this_month
      @ed = @curdate.end_of_month
      @sd = @ed.sub_days(6)
      @constructs << DateSpanConstruct.new(start_date: @sd, end_date: @ed, comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_last_week_ofthe_month
      @components[@pos + 2] == 'of' && @components[@pos + 3] == 'the' && @components[@pos + 4] == 'month'                  # 1st day this month
    end

    def found_last_week_ofthe_month
      @ed = @curdate.end_of_month
      @sd = @ed.sub_days(6)
      @constructs << DateSpanConstruct.new(start_date: @sd, end_date: @ed, comp_start: @pos, comp_end: @pos += 4, found_in: __method__)
    end

    def match_last_week_next_month
      @components[@pos + 2] == 'next' && @components[@pos + 3] == 'month'        # 1st day next month
    end

    def found_last_week_next_month
      @ed = @curdate.add_months(1).end_of_month
      @sd = @ed.sub_days(6)
      @constructs << DateSpanConstruct.new(start_date: @sd, end_date: @ed, comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_last_week_monthname
      @components[@pos + 2] =~ /(in|of)/ && @month_index = ZDate.months_of_year.index(@components[@pos + 3])
    end

    def found_last_week_monthname
      @ed = @curdate.jump_to_month(@month_index + 1).end_of_month
      @sd = @ed.sub_days(6)
      @constructs << DateSpanConstruct.new(start_date: @sd, end_date: @ed, comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_at
      @components[@pos] == 'at'
    end

    def match_at_time
      @components[@pos + 1] && @time1 = ZTime.interpret(@components[@pos + 1])
    end

    def match_at_time_through_time
      @components[@pos + 2] =~ /^(to|until|through)$/ && @components[@pos + 3] && @time2 = ZTime.interpret(@components[@pos + 3])
    end

    def found_at_time_through_time
      @constructs << TimeSpanConstruct.new(start_time: @time1, end_time: @time2, comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def found_at_time
      @constructs << TimeConstruct.new(time: @time1, comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
    end

    def match_all_day
      @components[@pos] == 'all' && @components[@pos + 1] == 'day'      # all day
    end

    # NOTE - THIS IS RIDICULOUS!!!!
    def found_all_day
      @constructs << NullConstruct.new(comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
    end

    def match_tomorrow
      @components[@pos] == 'tomorrow'
    end

    def match_tomorrow_through
      @components[@pos + 1] == 'until' || @components[@pos + 1] == 'to' || @components[@pos + 1] == 'through'    # "tomorrow through"
    end

    def match_tomorrow_through_dayname
      @day_index = ZDate.days_of_week.index(@components[@pos + 2])       # tomorrow through thursday
    end

    def found_tomorrow_through_dayname
      @constructs << DateSpanConstruct.new(start_date: @curdate.add_days(1), end_date: @curdate.add_days(1).this(@day_index), comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_tomorrow_through_date
      @date1 = ZDate.interpret(@components[@pos + 2], @curdate)       # tomorrow until 9/21
    end

    def found_tomorrow_through_date
      @constructs << DateSpanConstruct.new(start_date: @curdate.add_days(1), end_date: @date1, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def found_tomorrow
      @constructs << DateConstruct.new(date: @curdate.add_days(1), comp_start: @pos, comp_end: @pos, found_in: __method__)
    end

    def match_now
      @components[@pos] == 'today' || @components[@pos] == 'now'
    end

    def match_now_through
      @components[@pos + 1] == 'until' || @components[@pos + 1] == 'to' || @components[@pos + 1] == 'through'   # "today through"
    end

    def match_now_through_dayname
      @day_index = ZDate.days_of_week.index(@components[@pos + 2])     # today through thursday
    end

    def found_now_through_dayname
      @constructs << DateSpanConstruct.new(start_date: @curdate, end_date: @curdate.this(@day_index), comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    # redundant!! preprocess this out of here!
    def match_now_through_following_dayname
      @components[@pos + 2] =~ /following|this/ && @day_index = ZDate.days_of_week.index(@components[@pos + 3])    # today through following friday
    end

    # redundant!! preprocess this out of here!
    def found_now_through_following_dayname
      @constructs << DateSpanConstruct.new(start_date: @curdate, end_date: @curdate.this(@day_index), comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def match_now_through_date
      @date1 = ZDate.interpret(@components[@pos + 2], @curdate)       # now until 9/21
    end

    def found_now_through_date
      @constructs << DateSpanConstruct.new(start_date: @curdate, end_date: @date1, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_now_through_monthname
      @month_index = ZDate.months_of_year.index(@components[@pos + 2])
    end

    def found_now_through_monthname
      @constructs << DateSpanConstruct.new(start_date: @curdate, end_date: @curdate.jump_to_month(@month_index + 2).sub_days(1), comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_now_through_tomorrow
      @components[@pos + 2] == 'tomorrow'
    end

    def found_now_through_tomorrow
      @constructs << DateSpanConstruct.new(start_date: @curdate, end_date: @curdate.add_days(1), comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_now_through_next_dayname
      @components[@pos + 2] == 'next' && @day_index = ZDate.days_of_week.index(@components[@pos + 3])     # Today through next friday
    end

    def found_now_through_next_dayname
      @constructs << DateSpanConstruct.new(start_date: @curdate, end_date: @curdate.next(@day_index), comp_start: @pos, comp_end: @pos += 3, found_in: __method__)
    end

    def found_now
      @constructs << DateConstruct.new(date: @curdate, comp_start: @pos, comp_end: @pos, found_in: __method__)
    end

    def match_dayname
      @day_index = ZDate.days_of_week.index(@components[@pos])
    end

    def match_dayname_after_date
      @components[@pos + 1] == 'after' && @date1 = ZDate.interpret(@components[@pos + 2], @curdate)
    end

    def found_dayname_after_date
      date = @date1.add_days(7 - ((7 + @date1.dayindex - @day_index) % 7))
      @constructs << DateConstruct.new(date: date, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_dayname_before_date
      @components[@pos + 1] == 'before' && @date1 = ZDate.interpret(@components[@pos + 2], @curdate)
    end

    def found_dayname_before_date
      date = @date1.add_days(((7 - @date1.dayindex + @day_index) % 7) - 7)
      @constructs << DateConstruct.new(date: date, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def match_dayname_the_ordinal
      @components[@pos + 1] == 'the' && @date1 = ZDate.interpret(@components[@pos + 2], @curdate)    # if "tue the 23rd"
    end

    def found_dayname_the_ordinal
      # user may have specified "monday the 2nd" while in the previous month, so first check if dayname matches date.dayname, if it doesn't increment by a month and check again
      if @date1.dayname == @components[@pos] || ((tmp = @date1.add_months(1)) && tmp.dayname == @components[@pos] && @date1 = tmp)
        @constructs << DateConstruct.new(date: @date1, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
      end
    end

    def match_dayname_x_weeks_from_this
      @components[@pos + 1] && ConstructFinder.digits_only?(@components[@pos + 1]) && @components[@pos + 2] =~ /\bweeks?\b/ && @components[@pos + 3] =~ /\b(from)|(after)/ && @components[@pos + 4] == 'this' && @length = @components[@pos + 1]           # "monday two weeks from this
    end

    def found_dayname_x_weeks_from_this
      dc = DateConstruct.new(date: @curdate.this(@dayindex).add_weeks(@length), comp_start: @pos, found_in: __method__)
      if ZDate.days_of_week.include?(@components[@pos + 5])  # redundant
        dc.comp_end = @pos += 5
      else
        dc.comp_end = @pos += 4
      end
      @constructs << dc
    end

    def match_dayname_x_weeks_from_next
      @components[@pos + 1] && ConstructFinder.digits_only?(@components[@pos + 1]) && @components[@pos + 2] =~ /\bweeks?\b/ && @components[@pos + 3] =~ /\b(from)|(after)/ && @components[@pos + 4] == 'next' && @length = @components[@pos + 1]           # "monday two weeks from this
    end

    def found_dayname_x_weeks_from_next
      dc = DateConstruct.new(date: @curdate.next(@dayindex).add_weeks(@length), comp_start: @pos, found_in: __method__)
      if ZDate.days_of_week.include?(@components[@pos + 5])  # redundant
        dc.comp_end = @pos += 5
      else
        dc.comp_end = @pos += 4
      end
      @constructs << h
    end

    def match_dayname_after_next
      @components[@pos + 1] == 'after' && @components[@pos + 2] == 'next' # "monday after next
    end

    def found_dayname_after_next
      day_to_add = @curdate.after_next(@day_index)
      @constructs << DateConstruct.new(date: day_to_add, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
#      while @components[@pos + 1] && @day_index = ZDate.days_of_week.index(@components[@pos + 1])
#        # note @pos gets incremented on each pass
#        @constructs << DateConstruct.new(date: day_to_add = day_to_add.this(@day_index), comp_start: @pos + 1, comp_end: @pos += 1, found_in: __method__)
#      end
    end

    def found_dayname
      day_to_add = @curdate.x_weeks_from_day(@week_index, @day_index)
      if day_to_add <= @curdate
        day_to_add = day_to_add.add_weeks(1)
      end
      @constructs << DateConstruct.new(date: day_to_add, comp_start: @pos, comp_end: @pos, found_in: __method__)
    end

    def match_through_monthname
      @components[@pos] == 'through' && @month_index = ZDate.months_of_year.index(@components[@pos + 1])
    end

    def found_through_monthname
      # through signifies till the end of the month
      @constructs << WrapperConstruct.new(wrapper_type: 1, comp_start: @pos, comp_end: @pos + 1, found_in: __method__)
      @constructs << DateConstruct.new(date: @curdate.jump_to_month(@month_index + 2).sub_days(1), comp_start: @pos, comp_end: @pos += 1, found_in: __method__)
    end

    def match_monthname
      # note it is important that all other uses of monthname come after indicating words such as "the third day of december"; otherwise they will be converted here
      @month_index = ZDate.months_of_year.index(@components[@pos])
    end

    def found_monthname
      sd = @curdate.jump_to_month(@month_index + 1)
      ed = sd.end_of_month
      @constructs << DateSpanConstruct.new(start_date: sd, end_date: ed, comp_start: @pos, comp_end: @pos, found_in: __method__)
    end

    def match_start
      @components[@pos] == 'start'
    end

    def found_start
      # wrapper_type 0 is a start wrapper
#      @constructs << WrapperConstruct.new(wrapper_type: 0, comp_start: @pos, comp_end: @pos, found_in: __method__)
    end

    def match_through
      @components[@pos] == 'through'
    end

    def found_through
      # wrapper_type 1 is an end wrapper
      @constructs << WrapperConstruct.new(wrapper_type: 1, comp_start: @pos, comp_end: @pos, found_in: __method__)
    end


    def match_time
      @time1 = ZTime.interpret(@components[@pos])
    end

    def match_time_through_time
      @components[@pos + 1] =~ /^(to|through)$/ && @time2 = ZTime.interpret(@components[@pos + 2])
    end

    def found_time_through_time
      @constructs << TimeSpanConstruct.new(start_time: @time1, end_time: @time2, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def found_time
      @constructs << TimeConstruct.new(time: @time1, comp_start: @pos, comp_end: @pos, found_in: __method__)
    end

    def match_date
      @date1 = ZDate.interpret(@components[@pos], @curdate)
    end

    def match_date_through_date
      @components[@pos + 1] =~ /^(through|to|until)$/ && @date2 = ZDate.interpret(@components[@pos + 2], @curdate)
    end

    def found_date_through_date
      @constructs << DateSpanConstruct.new(start_date: @date1, end_date: @date2, comp_start: @pos, comp_end: @pos += 2, found_in: __method__)
    end

    def found_date
      @constructs << DateConstruct.new(date: @date1, comp_start: @pos, comp_end: @pos, found_in: __method__)
    end

    class << self
      def digits_only?(str)
        str =~ /^\d+$/ # no characters other than digits
      end

      # valid hour, 24hour, and minute could use some cleaning
      def ordinal_only?(str)
        str =~ %r{^(0?[1-9]|[12][0-9]|3[01])(?:st|nd|rd|th)?$}
      end
    end
  end # END class ConstructFinder
end
