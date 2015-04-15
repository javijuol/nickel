# these might be required as part of post-API processing
require 'nickel/zdate'
require 'nickel/ztime'
require 'nickel/nlp_query_constants'
require 'easy_translate'


module Nickel
  class NLPTranslate

    def initialize(query_str)
      @query_str = query_str.dup
    end

    def translate
      # run the API here
      EasyTranslate.api_key = 'AIzaSyBRkb0i9k2VO4B9N7731oBhrT-VS56UNbQ'
      language = EasyTranslate.detect(@query_str)
      @query_str = EasyTranslate.translate(@query_str, :to => :en)

      # post-API processing - based on returned language
      case language
        when 'es'           # Spanish
          @query_str = 'tomorrow' if @query_str.downcase == 'morning'   ## because translates "manana" as "morning"
          @query_str.gsub!(/\bfirst thing in the morning\b/, '8am through 10am')
          @query_str.gsub!(/\bearly\b/, '8am through 10am')
          @query_str.gsub!(/\blate in the morning\b/,'1pm through 2pm')
          @query_str.gsub!(/\bmid-morning\b/,'12pm')
          @query_str.gsub!(/\bmorning\b/,'8am through 2pm')
          @query_str.gsub!(/\blunchtime\b/,'1:30pm through 3:30pm')
          @query_str.gsub!(/\blate afternoon\b/,'6pm through 8pm')
          @query_str.gsub!(/\bafternoon\b/,'3pm through 8pm')
      end

      p @query_str, language
      return @query_str
    end
  end
end


