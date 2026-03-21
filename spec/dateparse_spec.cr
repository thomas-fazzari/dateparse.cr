require "./spec_helper"

describe DateParse do
  describe ".parse" do
    it "returns nil for empty string" do
      DateParse.parse("").should be_nil
    end

    it "returns nil for whitespace" do
      DateParse.parse("   ").should be_nil
    end

    it "returns nil for garbage" do
      DateParse.parse("not a date").should be_nil
    end

    it "never raises on garbage" do
      ["garbage", "0", "Jan", "2006-99-99", "99:99:99"].each do |bad|
        DateParse.parse(bad).should be_nil
      end
    end
  end

  describe ".parse!" do
    it "raises DateParse::Error on invalid input" do
      expect_raises(DateParse::Error) { DateParse.parse!("not a date") }
    end

    it "raises DateParse::Error specifically (not base Exception)" do
      expect_raises(DateParse::Error) { DateParse.parse!("garbage") }
    end

    it "returns Time on valid input" do
      DateParse.parse!("2006-01-02T15:04:05Z").year.should eq(2006)
    end
  end

  describe "RFC 3339" do
    it "parses UTC Z suffix" do
      t = DateParse.parse("2006-01-02T15:04:05Z")
      t.should_not be_nil
      t.try(&.year).should eq(2006)
      t.try(&.month).should eq(1)
      t.try(&.day).should eq(2)
    end

    it "parses with positive offset" do
      DateParse.parse("2006-01-02T15:04:05+07:00").should_not be_nil
    end

    it "parses with negative offset" do
      DateParse.parse("2006-01-02T15:04:05-05:00").should_not be_nil
    end

    it "parses with fractional seconds" do
      t = DateParse.parse("2006-01-02T15:04:05.999Z")
      t.try(&.year).should eq(2006)
    end

    it "parses without timezone (assumes UTC)" do
      DateParse.parse("2006-01-02T15:04:05").should_not be_nil
    end
  end

  describe "RFC 2822" do
    it "parses with numeric timezone" do
      t = DateParse.parse("Mon, 02 Jan 2006 15:04:05 +0000")
      t.try(&.year).should eq(2006)
    end

    it "parses without day of week" do
      DateParse.parse("02 Jan 2006 15:04:05 +0000").should_not be_nil
    end

    it "parses without seconds" do
      DateParse.parse("Mon, 02 Jan 2006 15:04 +0000").should_not be_nil
    end

    it "parses MST abbreviation" do
      t = DateParse.parse("Mon, 02 Jan 2006 15:04:05 MST")
      t.try(&.offset).should eq(-7 * 3600)
    end

    it "parses EST abbreviation" do
      t = DateParse.parse("Mon, 02 Jan 2006 15:04:05 EST")
      t.try(&.offset).should eq(-5 * 3600)
    end

    it "parses GMT abbreviation" do
      t = DateParse.parse("Mon, 02 Jan 2006 15:04:05 GMT")
      t.try(&.offset).should eq(0)
    end

    it "parses UT abbreviation" do
      t = DateParse.parse("Mon, 02 Jan 2006 15:04:05 UT")
      t.try(&.offset).should eq(0)
    end

    it "parses colon offset (+01:00)" do
      DateParse.parse("Mon, 02 Jan 2006 15:04:05 +01:00").should_not be_nil
    end
  end

  describe "RFC 822" do
    it "parses 2-digit year" do
      DateParse.parse("02 Jan 06 15:04 +0000").should_not be_nil
    end

    it "parses 2-digit year 00 as 2000" do
      t = DateParse.parse("02 Jan 00 15:04 +0000")
      t.try(&.year).should eq(2000)
    end

    it "parses 2-digit year with seconds" do
      DateParse.parse("02 Jan 06 15:04:05 +0000").should_not be_nil
    end
  end

  describe "ISO 8601 variants" do
    it "parses compact offset (no colon)" do
      DateParse.parse("2006-01-02T15:04:05+0700").should_not be_nil
    end
  end

  describe "SQL-like" do
    it "parses datetime with timezone" do
      DateParse.parse("2006-01-02 15:04:05 +0000").should_not be_nil
    end

    it "parses datetime without timezone" do
      DateParse.parse("2006-01-02 15:04:05").should_not be_nil
    end
  end

  describe "Partial dates" do
    it "parses date only (YYYY-MM-DD)" do
      t = DateParse.parse("2006-01-02")
      t.try(&.year).should eq(2006)
      t.try(&.month).should eq(1)
      t.try(&.day).should eq(2)
    end

    it "parses year-month (YYYY-MM) — first of month" do
      t = DateParse.parse("2006-01")
      t.try(&.year).should eq(2006)
      t.try(&.month).should eq(1)
      t.try(&.day).should eq(1)
    end

    it "parses year only (YYYY) — Jan 1" do
      t = DateParse.parse("2006")
      t.try(&.year).should eq(2006)
      t.try(&.month).should eq(1)
      t.try(&.day).should eq(1)
    end

    it "parses abbreviated month + year (Jan 2006)" do
      t = DateParse.parse("Jan 2006")
      t.try(&.year).should eq(2006)
      t.try(&.month).should eq(1)
    end

    it "parses full month name + year (January 2006)" do
      t = DateParse.parse("January 2006")
      t.try(&.year).should eq(2006)
      t.try(&.month).should eq(1)
    end
  end

  describe "HTTP date (RFC 7231)" do
    it "parses RFC 1123 format" do
      t = DateParse.parse("Sat, 21 Mar 2026 00:00:00 GMT")
      t.try(&.year).should eq(2026)
      t.try(&.month).should eq(3)
      t.try(&.day).should eq(21)
    end

    it "parses RFC 850 (obsolete)" do
      DateParse.parse("Saturday, 21-Mar-26 00:00:00 GMT").should_not be_nil
    end

    it "parses ANSI C asctime" do
      DateParse.parse("Sat Mar 21 00:00:00 2026").should_not be_nil
    end
  end

  describe "Robustness" do
    it "handles leading/trailing whitespace" do
      DateParse.parse("  2006-01-02T15:04:05Z  ").should_not be_nil
    end

    it "handles tab characters" do
      DateParse.parse("\t2006-01-02T15:04:05Z\t").should_not be_nil
    end

    it "handles multiple internal spaces (asctime-style)" do
      DateParse.parse("Sat Mar  1 00:00:00 2026").should_not be_nil
    end

    it "returns nil for nil-like inputs" do
      ["", "   ", "\t", "\n"].each do |blank|
        DateParse.parse(blank).should be_nil
      end
    end
  end

  describe "Unix timestamps" do
    it "parses integer epoch seconds" do
      t = DateParse.parse("1136214245")
      t.should_not be_nil
      t.try(&.year).should eq(2006)
    end

    it "parses negative epoch (pre-1970)" do
      DateParse.parse("-1000").should_not be_nil
    end

    it "parses epoch milliseconds (13 digits)" do
      t = DateParse.parse("1136214245000")
      t.try(&.year).should eq(2006)
    end
  end
end
