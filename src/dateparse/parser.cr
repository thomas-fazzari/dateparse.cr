module DateParse
  class Error < Exception; end

  TZ_ABBR = {
    "UT"  => "+0000",
    "GMT" => "+0000",
    "EST" => "-0500",
    "EDT" => "-0400",
    "CST" => "-0600",
    "CDT" => "-0500",
    "MST" => "-0700",
    "MDT" => "-0600",
    "PST" => "-0800",
    "PDT" => "-0700",
  }

  FORMATS = [
    "%a, %d %b %Y %H:%M:%S %z", # RFC 2822 (Mon, 02 Jan 2006 15:04:05 +0000)
    "%d %b %Y %H:%M:%S %z",     # RFC 2822 (no day-of-week)
    "%a, %d %b %Y %H:%M %z",    # RFC 2822 (no seconds)
    "%d %b %Y %H:%M %z",        # RFC 2822 (no day-of-week, no seconds)
    "%d %b %y %H:%M %z",        # RFC 822  (2-digit year, 02 Jan 06 15:04 +0000)
    "%d %b %y %H:%M:%S %z",     # RFC 822  (2-digit year, with seconds)
    "%Y-%m-%dT%H:%M:%S%z",      # ISO 8601 (compact offset +0700, no colon)
    "%Y-%m-%d %H:%M:%S %z",     # SQL-like (2006-01-02 15:04:05 +0000)
    "%Y-%m-%d %H:%M:%S",        # SQL-like (no timezone, assumed UTC)
    "%A, %d-%b-%y %H:%M:%S %z", # RFC 850  (Saturday, 21-Mar-26 00:00:00 GMT)
    "%a %b %d %H:%M:%S %Y",     # asctime  (Sat Mar 21 00:00:00 2026)
    "%a %b  %d %H:%M:%S %Y",    # asctime  (double space for single-digit day, Sat Mar  1 ...)
  ]

  # Incomplete date strings, each regex guards a strftime format so
  # Time.parse is only attempted when the shape matches exactly
  PARTIAL_PATTERNS = {
    "%Y-%m-%d" => /\A\d{4}-\d{2}-\d{2}\z/,
    "%Y-%m"    => /\A\d{4}-\d{2}\z/,
    "%Y"       => /\A\d{4}\z/,
    "%B %Y"    => /\A[A-Za-z]+ \d{4}\z/,
  }

  COLON_OFFSET_RE = /([+-]\d{2}):(\d{2})\z/

  def self.parse(date_str : String) : Time?
    return if date_str.blank?
    s = date_str.strip
    try_rfc3339(s) || try_iso_no_tz(s) || try_formats(s) || try_partial(s) || try_unix(s)
  end

  def self.parse!(date_str : String) : Time
    parse(date_str) || raise Error.new("Cannot parse date: #{date_str.inspect}")
  end

  private def self.try_rfc3339(s : String) : Time?
    Time.parse_rfc3339(s)
  rescue Exception
    nil
  end

  private def self.try_iso_no_tz(s : String) : Time?
    Time.parse(s, "%Y-%m-%dT%H:%M:%S", Time::Location::UTC)
  rescue Exception
    nil
  end

  private def self.try_formats(s : String) : Time?
    normalized = normalize_tz(s)
    FORMATS.each do |fmt|
      result = Time.parse(normalized, fmt, Time::Location::UTC)
      return result
    rescue Exception
    end
  end

  private def self.try_partial(s : String) : Time?
    PARTIAL_PATTERNS.each do |fmt, pattern|
      next unless s.matches?(pattern)
      result = Time.parse(s, fmt, Time::Location::UTC)
      return result
    rescue Exception
    end
  end

  private def self.try_unix(s : String) : Time?
    return unless s.size >= 4
    n = s.to_i64? || return
    n > 9_999_999_999_i64 ? Time.unix_ms(n) : Time.unix(n)
  end

  private def self.normalize_tz(s : String) : String
    s = s.gsub(COLON_OFFSET_RE, "\\1\\2")
    last = s[-1]?
    return s if last == 'Z' || last.try(&.ascii_number?)
    prefix, _, abbr = s.rpartition(' ')
    return s if abbr.empty?
    if offset = TZ_ABBR[abbr]?
      "#{prefix}#{offset}"
    else
      s
    end
  end
end
