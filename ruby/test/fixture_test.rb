# -*- coding: utf-8 -*-

###
### $Release: 1.1.0 $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class FixtureManager_TC < TC

  class DummyReporter2 < Oktest::Reporter
    def exit_spec(spec, depth, status, error, parent)
      puts error.inspect if error
    end
  end

  def run_all(dummy: false)
    reporter = dummy ? DummyReporter2.new : Oktest::Reporter.new
    sout, serr = capture do
      Oktest::Runner.new(reporter).start()
    end
    assert_eq serr, ""
    return sout
  end

  describe '#get_fixture_values()' do

    it "[!v587k] resolves fixtures." do
      Oktest.scope do
        fixture(:x) { 10 }
        topic "Parent" do
          fixture(:y) { 20 }
          topic "Child" do
            fixture(:z) { 30 }
            spec "fixture test" do |x, y, z|
              p [x, y, z]
            end
          end
        end
      end
      expected = "[10, 20, 30]\n"
      sout = run_all()
      assert_eq sout, expected
    end

    it "[!ja2ew] resolves 'this_spec' fixture name as description of current spec." do
      Oktest.scope do
        topic Integer do
          spec "1+1 should be 2." do |this_spec|
            puts "this_spec=#{this_spec.inspect}"
          end
        end
      end
      sout = run_all()
      assert_eq sout, "this_spec=\"1+1 should be 2.\"\n"
    end

    it "[!w6ffs] resolves 'this_topic' fixture name as target objec of current topic." do
      Oktest.scope do
        topic Integer do
          spec "1+1 should be 2." do |this_topic|
            puts "this_topic=#{this_topic.inspect}"
          end
        end
      end
      sout = run_all()
      assert_eq sout, "this_topic=Integer\n"
    end

    it "[!np4p9] raises error when loop exists in dependency." do
      Oktest.scope do
        topic "Parent" do
          fixture(:a) {|b| nil }
          fixture(:b) {|c| nil }
          fixture(:c) do |d| nil end
          fixture(:d) do |b| nil end
          topic "Child" do
            spec("spec#1") {|a| p a }
          end
        end
      end
      expected = "\#<Oktest::LoopedDependencyError: fixture dependency is looped: a->b=>c=>d=>b>\n"
      sout = run_all(dummy: true)
      assert_eq sout, expected
    end

  end

  describe '#get_fixture_value()' do

    it "[!2esaf] resolves fixture dependencies." do
      Oktest.scope do
        topic "Parent" do
          fixture(:a) {|b, c| ["A"] + b + c }
          fixture(:b) { ["B"] }
          fixture(:c) do |d| ["C"] + d end
          fixture(:d) do ["D"] end
          topic "Child" do
            spec "spec#1" do |a|
              p a
            end
            spec("spec#2") {|a|
              p a
            }
          end
        end
      end
      expected = <<'END'
["A", "B", "C", "D"]
["A", "B", "C", "D"]
END
      sout = run_all()
      assert_eq sout, expected
    end

    it "[!4xghy] calls fixture block with context object as self." do
      Oktest.scope do
        topic "Parent" do
          fixture(:x) { @x = 10; 20 }
          spec("spec#1") {|x| p @x }
        end
      end
      expected = <<'END'
10
END
      sout = run_all()
      assert_eq sout, expected
    end

    it "[!8t3ul] caches fixture value to call fixture block only once per spec." do
      Oktest.scope do
        topic "Parent" do
          fixture(:x) { puts "** x called."; 10 }
          fixture(:y) {|x| x + 1 }
          fixture(:z) {|x| x + 2 }
          spec("spec#1") {|y, z|
            p y
            p z
          }
        end
      end
      expected = <<'END'
** x called.
11
12
END
      sout = run_all()
      assert_eq sout, expected
    end

    it "[!4chb9] traverses parent topics if fixture not found in current topic." do
      Oktest.scope do
        topic 'Parent' do
          fixture(:x) { 10 }
          topic 'Child' do
            fixture(:y) {|x| x + 1 }
            topic 'GrandChild' do
              fixture(:z) {|x| x + 2 }
              spec("spec#1") do |x, y, z| p "x=#{x}, y=#{y}, z=#{z}" end
            end
          end
        end
      end
      sout = run_all()
      assert_eq sout, "\"x=10, y=11, z=12\"\n"
    end

    it "[!wt3qk] suports global scope." do
      Oktest.global_scope do
        fixture :gf1592 do {id: "gf1592"} end
        fixture :gf6535 do |gf1592| {id: "gf6535", parent: gf1592} end
      end
      Oktest.global_scope do
        fixture :gf8979 do |gf6535| {id: "gf8979", parent: gf6535} end
      end
      data = nil
      Oktest.scope do
        topic "global fixtures" do
          spec "example" do |gf8979| data = gf8979 end
        end
      end
      _ = run_all()
      assert_eq data, {:id=>"gf8979", :parent=>{:id=>"gf6535", :parent=>{:id=>"gf1592"}}}
    end

    it "[!nr79z] raises error when fixture not found." do
      Oktest.scope do
        topic "Parent" do
          fixture(:x) { 10 }
          topic "Child" do
            spec("spec#1") {|y| p y }
          end
        end
      end
      expected = "#<Oktest::FixtureNotFoundError: y: fixture not found. (spec: spec#1)>\n"
      sout = run_all(dummy: true)
      assert_eq sout, expected
    end

  end

end
