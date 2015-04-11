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
      end

      p @query_str, language
      return @query_str
    end
  end
end


