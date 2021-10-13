# frozen_string_literal: true

class Normalizer
  attr_reader :source

  def initialize(source)
    @source = source
    if source.present?
      @rules = source.split("|").map do |rule|
        parse_rule(rule)
      end.compact
    end
  end

  def parse_rule(rule)
    return unless rule =~ /\/.*\//

    escaping = false
    regex = +""
    sub = +""
    c = 0

    rule.chars.each do |l|
      c += 1 if !escaping && l == "/"
      escaping = l == "\\"

      if c > 1
        sub << l
      else
        regex << l
      end
    end

    if regex.length > 1
      [Regexp.new(regex[1..-1]), sub[1..-1] || ""]
    end
  end

  def normalize(url)
    return url unless @rules

    @rules.each do |(regex, sub)|
      url = url.sub(regex, sub)
    end

    url
  end

  def normalize_all(url)
    return url unless @rules

    @rules.each do |(regex, sub)|
      url = url.gsub(regex, sub)
    end

    url
  end
end
