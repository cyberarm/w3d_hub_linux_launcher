# The I18n gem is a real pain to work with when packaging with Ocra(n)
# and we're not using its 'advanced' features so emulate its API here.

require "yaml"

class I18n
  class InvalidLocale < StandardError
  end

  @locale = :en
  @default_locale = :en
  @load_path = []

  @translations = {}

  def self.load_path
    @load_path
  end

  def self.default_locale
    @default_locale.to_sym
  end

  def self.default_locale=(locale)
    @default_locale = locale.to_s
  end

  def self.locale
    @locale.to_sym
  end

  def self.locale=(locale)
    locale = locale.to_s

    raise InvalidLocale unless valid_locale?(locale)

    @locale = locale
  end

  def self.t(symbol)
    return symbol.to_s unless valid_locale?(@locale)

    @translations[@locale] || load_locale(@locale)

    translations = @translations[@locale]
    return translations[symbol] if translations

    translation = @translations.dig(@default_locale, symbol)
    return translation if translation

    return symbol.to_s
  end

  def self.available_locales
    @load_path.flatten.map { |f| File.basename(f, ".yml").to_s.downcase.to_sym }
  end

  private
  def self.load_locale(locale)
    locale = locale.to_s

    return if @translations[locale] && !@translations[locale].empty?

    if (file = valid_locale?(locale))
      yaml = YAML.load_file(file)

      raise InvalidLocale unless yaml[locale]

      key = ""
      hash = yaml[locale]
      hash.each_pair do |key, v|
        if v.is_a?(String)
          @translations[locale] ||= {}
          @translations[locale][key.to_sym] = v
        else
          load_locale_part(locale, key, v)
        end
      end
    end
  end

  def self.load_locale_part(locale, key, part)
    locale = locale.to_s

    part.each_pair do |k, v|
      if v.is_a?(String)
        @translations[locale] ||= {}
        @translations[locale]["#{key}.#{k}".to_sym] = v
      else
        load_locale_part(locale, "#{key}.#{k}", v)
      end
    end
  end

  def self.valid_locale?(locale)
    locale = locale.to_s

    @load_path.flatten.find do |file|
      File.basename(file, ".yml").to_s.downcase.strip == locale
    end
  end
end
