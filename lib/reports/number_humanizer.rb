require 'active_support/dependencies/autoload'
require 'active_support/number_helper'

# Silence warnings caused by including ActiveSupport and I18n.
I18n.enforce_available_locales = true

module Reports
  module NumberHumanizer
    def humanize_number(number_of_bytes)
      converter = ActiveSupport::NumberHelper::NumberToHumanSizeConverter
      humanized = converter.new(number_of_bytes, {}).convert
      humanized.sub(/Bytes?/, 'B')
    end
  end
end
