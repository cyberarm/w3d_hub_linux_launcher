require "csv"
require "yaml"

PATH = File.expand_path(".", __dir__)
TRANSLATIONS_PATH = "#{PATH}/translations.csv".freeze

puts "Loading translations.csv [Using ■ as column seperator]"

TRANSLATIONS = {}
LANGUAGES = []

i = 0
CSV.foreach("#{PATH}/translations.csv", col_sep: "■") do |row|
  key = row.delete(row.first)

  if i.zero?
    row.map { |language| language.split("-").first.downcase }.each do |language|
      TRANSLATIONS[language] ||= {}
      LANGUAGES << language
    end
  else
    row.each_with_index do |translation, lang_id|
      next unless translation
      next if key.empty? || key.nil?

      hash = TRANSLATIONS[LANGUAGES[lang_id]]

      parts = key.split(".")
      parts_size = parts.size
      key = parts.delete(parts.last) if parts.size > 1

      if parts_size > 1
        parts.each do |part|
          hash = hash[part] ||= {}
        end
      end

      hash[key] = translation
    end
  end

  i += 1
end

puts "Done."

puts
puts "Removing existing translations..."
Dir.glob("#{PATH}/*.yml") do |file|
  File.delete(file)
end
puts "Done."

puts
puts "Writing out translations..."

written_languages = []
LANGUAGES.each do |language|
  translations = TRANSLATIONS[language]

  next unless translations.size.positive?

  yaml = YAML.dump({ language => translations })

  written_languages << language
  File.write("#{PATH}/#{language}.yml", yaml)
end

puts "Done."
puts
puts "Wrote translations for: #{written_languages.join(', ')}"
