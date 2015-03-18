# these might be required as part of post-API processing
require 'nickel/zdate'
require 'nickel/ztime'
require 'nickel/nlp_query_constants'


module Nickel
  class NLPTranslate

    def initialize(query_str)
      @query_str = query_str.dup
    end

    def translate
      # run the API here


      # post-API processing - based on returned language

      return @query_str
    end
  end
end


