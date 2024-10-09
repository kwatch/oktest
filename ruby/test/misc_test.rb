# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: $
### $Copyright: copyright(c) 2011-2024 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './init'


Object.new.instance_eval do   # Oktest
  extend NanoTest

  def self.test_subject(desc, &b)
    auto_run = Oktest::Config.auto_run
    Oktest::Config.auto_run = true
    NanoTest.test_subject(desc, &b)
  ensure
    Oktest::Config.auto_run = auto_run
    Oktest::THE_GLOBAL_SCOPE.clear_children()
  end

  test_target 'Oktest.auto_run?()' do
    test_subject "[!7vm4d] returns false if error raised when loading test scripts." do
      Oktest.scope do
      end
      begin
        1/0
      rescue => exc
        test_eq? Oktest.auto_run?, false
      end
      test_ok? exc != nil, msg: "exception not raised"
    end
    test_subject "[!oae85] returns true if exit() called." do
      Oktest.scope do
      end
      #
      begin
        exit(0)
      rescue SystemExit => exc
        test_eq? Oktest.auto_run?, true
      end
      test_ok? exc != nil, msg: "exception not raised"
    end
    test_subject "[!rg5aw] returns false if Oktest.scope() never been called." do
      test_eq? Oktest::THE_GLOBAL_SCOPE.has_child?, false
      test_eq? Oktest.auto_run?, false
    end
    test_subject "[!0j3ek] returns true if Config.auto_run is enabled." do
      Oktest.scope do
      end
      bkup = Oktest::Config.auto_run
      begin
        Oktest::Config.auto_run = true
        test_eq? Oktest.auto_run?, true
        Oktest::Config.auto_run = false
        test_eq? Oktest.auto_run?, false
      ensure
        Oktest::Config.auto_run = bkup
      end
    end
  end

end


Object.new.instance_eval do   # Oktest::Color
  extend NanoTest

  test_target 'Oktest::Color.status()' do
    test_subject "[!yev5y] returns string containing color escape sequence." do
      test_eq? Oktest::Color.status(:PASS , "Pass" ), "\e[0;36mPass\e[0m"
      test_eq? Oktest::Color.status(:FAIL , "Fail" ), "\e[0;31mFail\e[0m"
      test_eq? Oktest::Color.status(:ERROR, "Error"), "\e[1;31mError\e[0m"
      test_eq? Oktest::Color.status(:SKIP , "Skip" ), "\e[0;33mSkip\e[0m"
      test_eq? Oktest::Color.status(:TODO , "Todo" ), "\e[0;33mTodo\e[0m"
    end
  end

end
