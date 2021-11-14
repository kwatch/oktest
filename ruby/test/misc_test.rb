# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class Misc_TC < TC

  def setup()
    @_auto_run = Oktest::Config.auto_run
    Oktest::Config.auto_run = true
  end

  def teardown()
    Oktest::Config.auto_run = @_auto_run
    Oktest::THE_GLOBAL_SCOPE.clear_children()
  end

  describe 'Oktest.auto_run?()' do
    it "[!7vm4d] returns false if error raised when loading test scripts." do
      Oktest.scope do
      end
      begin
        1/0
      rescue => exc
        assert_eq Oktest.auto_run?, false
      end
      assert exc != nil, "exception not raised"
    end
    it "[!oae85] returns true if exit() called." do
      Oktest.scope do
      end
      #
      begin
        exit(0)
      rescue SystemExit => exc
        assert_eq Oktest.auto_run?, true
      end
      assert exc != nil, "exception not raised"
    end
    it "[!rg5aw] returns false if Oktest.scope() never been called." do
      assert_eq Oktest::THE_GLOBAL_SCOPE.has_child?, false
      assert_eq Oktest.auto_run?, false
    end
    it "[!0j3ek] returns true if Config.auto_run is enabled." do
      Oktest.scope do
      end
      bkup = Oktest::Config.auto_run
      begin
        Oktest::Config.auto_run = true
        assert_eq Oktest.auto_run?, true
        Oktest::Config.auto_run = false
        assert_eq Oktest.auto_run?, false
      ensure
        Oktest::Config.auto_run = bkup
      end
    end
  end

end


class Color_TC < TC

  describe '.status()' do
    it "[!yev5y] returns string containing color escape sequence." do
      assert_eq Oktest::Color.status(:PASS , "Pass" ), "\e[1;36mPass\e[0m"
      assert_eq Oktest::Color.status(:FAIL , "Fail" ), "\e[1;31mFail\e[0m"
      assert_eq Oktest::Color.status(:ERROR, "Error"), "\e[1;31mError\e[0m"
      assert_eq Oktest::Color.status(:SKIP , "Skip" ), "\e[1;33mSkip\e[0m"
      assert_eq Oktest::Color.status(:TODO , "Todo" ), "\e[1;33mTodo\e[0m"
    end
  end

end
