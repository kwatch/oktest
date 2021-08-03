# -*- coding: utf-8 -*-

###
### $Release: $
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

  it "resolves fixtures." do
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
    sout, serr = capture do
      Oktest::Runner.new(Oktest::Reporter.new).run_all()
    end
    expected = "[10, 20, 30]\n"
    assert_eq sout, expected
    assert_eq serr, ""
  end

  it "resolves fixture dependencies." do
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
    sout, serr = capture do
      Oktest::Runner.new(Oktest::Reporter.new).run_all()
    end
    expected = <<'END'
["A", "B", "C", "D"]
["A", "B", "C", "D"]
END
    assert_eq sout, expected
    assert_eq serr, ""
  end

  it "calls fixture block with context object as self." do
    Oktest.scope do
      topic "Parent" do
        fixture(:x) { @x = 10; 20 }
        spec("spec#1") {|x| p @x }
      end
    end
    sout, serr = capture do
      Oktest::Runner.new(Oktest::Reporter.new).run_all()
    end
    expected = <<'END'
10
END
    assert_eq sout, expected
    assert_eq serr, ""
  end

  it "caches fixture value to call fixture block only once per spec." do
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
    sout, serr = capture do
      Oktest::Runner.new(Oktest::Reporter.new).run_all()
    end
    expected = <<'END'
** x called.
11
12
END
    assert_eq sout, expected
    assert_eq serr, ""
  end

  it "resolves 'spec' fixture name as description of current spec." do
    Oktest.scope do
      topic Integer do
        spec "1+1 should be 2." do |spec|
          puts "spec=#{spec.inspect}"
        end
      end
    end
    sout, serr = capture do
      Oktest::Runner.new(Oktest::Reporter.new).run_all()
    end
    assert_eq sout, "spec=\"1+1 should be 2.\"\n"
    assert_eq serr, ""
  end

  it "resolves 'topic' fixture name as target objec of current topic." do
    Oktest.scope do
      topic Integer do
        spec "1+1 should be 2." do |topic|
          puts "topic=#{topic.inspect}"
        end
      end
    end
    sout, serr = capture do
      Oktest::Runner.new(Oktest::Reporter.new).run_all()
    end
    assert_eq sout, "topic=Integer\n"
    assert_eq serr, ""
  end

  it "suports global scope." do
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
    sout, serr = capture do
      Oktest::Runner.new(DummyReporter2.new).run_all()
    end
    assert_eq data, {:id=>"gf8979", :parent=>{:id=>"gf6535", :parent=>{:id=>"gf1592"}}}
  end

  it "raises error when fixture not found." do
    Oktest.scope do
      topic "Parent" do
        fixture(:x) { 10 }
        topic "Child" do
          spec("spec#1") {|y| p y }
        end
      end
    end
    sout, serr = capture do
      Oktest::Runner.new(DummyReporter2.new).run_all()
    end
    expected = "#<Oktest::FixtureNotFoundError: y: fixture not found. (spec: spec#1)>\n"
    assert_eq sout, expected
    assert_eq serr, ""
  end

  it "raises error when loop exists in dependency." do
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
    sout, serr = capture do
      Oktest::Runner.new(DummyReporter2.new).run_all()
    end
    expected = "\#<Oktest::LoopedDependencyError: fixture dependency is looped: a->b=>c=>d=>b>\n"
    assert_eq sout, expected
    assert_eq serr, ""
  end

end
