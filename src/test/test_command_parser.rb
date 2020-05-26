# -*- coding: utf-8 -*-

require 'test/unit'
require 'bcdiceCore'
require 'utils/command_parser'

class TestCommandParser < Test::Unit::TestCase
  def setup
    @parser = CommandParser.new("LL", "SA")
  end

  def test_parse_full
    parsed = @parser.parse("LL@1#2+4<=5")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(1, parsed.critical)
    assert_equal(2, parsed.fumble)
    assert_equal(4, parsed.modify_number)
    assert_equal(:<=, parsed.cmp_op)
    assert_equal(5, parsed.target_number)
  end

  def test_command_only
    parsed = @parser.parse("LL")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(nil, parsed.critical)
    assert_equal(nil, parsed.fumble)
    assert_equal(0, parsed.modify_number)
    assert_equal(nil, parsed.cmp_op)
    assert_equal(nil, parsed.target_number)
  end

  def test_not_match
    parsed = @parser.parse("RR@1#2+4<=5")

    assert_equal(nil, parsed)
  end

  def test_negative_suffix
    parsed = @parser.parse("LL@-1#-2")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(-1, parsed.critical)
    assert_equal(-2, parsed.fumble)
  end

  def test_expr
    parsed = @parser.parse("LL@1#2-4*3+6/2<=-10/5+2*6")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(1, parsed.critical)
    assert_equal(2, parsed.fumble)
    assert_equal(-9, parsed.modify_number)
    assert_equal(:<=, parsed.cmp_op)
    assert_equal(10, parsed.target_number)
  end

  def test_reverse_critical
    parsed = @parser.parse("LL#1@2+4<=5")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(2, parsed.critical)
    assert_equal(1, parsed.fumble)
    assert_equal(4, parsed.modify_number)
    assert_equal(:<=, parsed.cmp_op)
    assert_equal(5, parsed.target_number)
  end

  def test_critical_only
    parsed = @parser.parse("LL@23")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(23, parsed.critical)
    assert_equal(nil, parsed.fumble)
  end

  def test_fumble_only
    parsed = @parser.parse("LL#23")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(nil, parsed.critical)
    assert_equal(23, parsed.fumble)
  end

  data("LL@2@5", "LL#2#5")
  def test_duplicate_suffix(data)
    parsed = @parser.parse(data)

    assert_equal(nil, parsed)
  end

  def test_no_suffix
    parsed = @parser.parse("LL+10>30")

    assert_equal("LL", parsed.command)
    assert_equal(nil, parsed.critical)
    assert_equal(nil, parsed.fumble)
    assert_equal(10, parsed.modify_number)
    assert_equal(:>, parsed.cmp_op)
    assert_equal(30, parsed.target_number)
  end
end
