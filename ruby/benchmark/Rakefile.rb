# coding: utf-8


$nfiles  = (ENV['N'] || 100).to_i
$ntopics = (ENV['T'] || 100).to_i
$nspecs  = (ENV['S'] || 10).to_i
$tail    = ENV['TAIL'] != 'off'
ENV['N'] = nil if ENV['N']   # to avoid warning of minitest


require 'erb'


class Renderer

  TEMPLATE_OKTEST = <<END
# coding: utf-8

require 'oktest'

Oktest.scope do
<% for i in 1..(ntopics/10) %>

  topic "Example #<%= i %>" do
<%   for j in 1..10 %>

    topic "Example #<%= i %>-<%= j %>" do

<%     for k in 1..nspecs %>
      spec "#<%= k %>: 1+1 should be 2" do
        ok {1+1} == 2
        ok {1+1} == 2
      end
<%     end %>

    end
<%   end %>

  end

<% end %>
end
END

  TEMPLATE_RSPEC = <<'END'
# coding: utf-8

<% for i in 1..(ntopics/10) %>

RSpec.describe "Example #<%= i %>" do
<%   for j in 1..10 %>

  describe "Example #<%= i %>-<%= j %>" do

<%     for k in 1..nspecs %>
    it "#<%= k %>: 1+1 should be 2" do
      expect(1+1).to eq 2
      expect(1+1).to eq 2
    end
<%     end %>

  end
<%   end %>

end
<% end %>
END

  TEMPLATE_MINITEST = <<'END'
# coding: utf-8

require 'minitest/spec'
require 'minitest/autorun'

<% for i in 1..(ntopics/10) %>

describe "Example #<%= i %>" do
<%   for j in 1..10 %>

  describe "Example #<% i %>-<%= j %>" do

<%     for k in 1..nspecs %>
    it "#<%= k %>: 1+1 should be 2" do
      assert_equal 2, 1+1
      assert_equal 2, 1+1
    end
<%     end %>

  end
<%   end %>

end
<% end %>
END

  TEMPLATE_TESTUNIT = <<'END'
# coding: utf-8

require 'test/unit'

<% n = nfile %>
<% for i in 1..(ntopics/10) %>

class Example_<%= n %>_<%= i %>_TC < Test::Unit::TestCase
<%   for j in 1..10 %>

  class Example_<%= n %>_<%= i %>_<%= j %>_TC < self

<%     for k in 1..nspecs %>
    def test_<%= n %>_<%= i %>_<%= j %>_<%= k %>()
      #assert 1+1 == 2
      assert_equal 2, 1+1
      assert_equal 2, 1+1
    end
<%     end %>

  end
<%   end %>

end
<% end %>
END

  def render(template_string, binding_)
    ERB.new(template_string, nil, '<>').result(binding_)
  end

  def render_oktest(nfile, ntopics, nspecs)
    render(TEMPLATE_OKTEST, binding())
  end

  def render_rspec(nfile, ntopics, nspecs)
    render(TEMPLATE_RSPEC, binding())
  end

  def render_minitest(nfile, ntopics, nspecs)
    render(TEMPLATE_MINITEST, binding())
  end

  def render_testunit(nfile, ntopics, nspecs)
    render(TEMPLATE_TESTUNIT, binding())
  end

end


task :default do
  system "rake -T"
end


namespace :benchmark do

  desc "remove 'example*_tst.rb' files"
  task :clean do
    FileUtils.rm_f Dir["example*_test.rb"]
  end

  def generate_files(&b)
    nfiles, ntopics, nspecs = $nfiles, $ntopics, $nspecs
    for n in 1..nfiles do
      content = yield n, ntopics, nspecs
      filename = "example%04d_test.rb" % n
      File.write(filename, content)
    end
  end

  def time(format=nil, &b)
    pt1 = Process.times()
    t1 = Time.now()
    yield
    t2 = Time.now()
    pt2 = Process.times()
    user = pt2.cutime - pt1.cutime
    sys  = pt2.cstime - pt1.cstime
    real = t2 - t1
    format ||= "\n        %.3f real        %.3f user        %.3f sys\n"
    $stderr.print format % [real, user, sys]
  end

  desc "start oktest benchmark"
  task :oktest => :clean do
    r = Renderer.new
    generate_files {|*args| r.render_oktest(*args) }
    #time { sh "oktest -sp run_all.rb" }
    time { sh "oktest -sq run_all.rb" }
  end

  desc "start oktest benchmark (with '--faster' option)"
  task :'oktest:faster' => :clean do
    r = Renderer.new
    generate_files {|*args| r.render_oktest(*args) }
    #time { sh "oktest -sp --faster run_all.rb" }
    time { sh "oktest -sq --faster run_all.rb" }
  end

  desc "start rspec benchmark"
  task :rspec do
    r = Renderer.new
    generate_files {|*args| r.render_rspec(*args) }
    time { sh "rspec run_all.rb | tail -4" } if $tail
    time { sh "rspec run_all.rb" }       unless $tail
  end

  desc "start minitest benchmark"
  task :minitest do
    r = Renderer.new
    generate_files {|*args| r.render_minitest(*args) }
    time { sh "ruby run_all.rb | tail -4" } if $tail
    time { sh "ruby run_all.rb" }       unless $tail
  end

  desc "start testunit benchmark"
  task :testunit do
    r = Renderer.new
    generate_files {|*args| r.render_testunit(*args) }
    time { sh "ruby run_all.rb | tail -5" } if $tail
    time { sh "ruby run_all.rb" }       unless $tail
  end

  desc "start all benchmarks"
  task :all do
    #$tail = true
    interval = 0
    [:oktest, :'oktest:faster', :rspec, :minitest, :testunit].each do |sym|
      puts ""
      sleep interval; interval = 1
      puts "==================== #{sym} ===================="
      #sh "rake benchmark:#{sym}"
      Rake.application["benchmark:#{sym}"].invoke()
    end
  end

end
