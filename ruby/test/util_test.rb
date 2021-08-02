# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class Util_TC < TC
  include Oktest::Util

  describe Oktest::Util do

    describe '#hhmmss()' do
      it "converts 400953.444 into '111:22:33.4'." do
        x = 111*60*60 + 22*60 + 33.444
        assert_eq x, 400953.444
        assert_eq hhmmss(x), "111:22:33.4"
      end
      it "converts 5025.678 into '1:23:45.7'." do
        x = 1*60*60 + 23*60 + 45.678
        assert_eq x, 5025.678
        assert_eq hhmmss(x), "1:23:45.7"
      end
      it "converts 754.888 into '12:34.9'." do
        x = 12*60 + 34.888
        assert_eq x, 754.888
        assert_eq hhmmss(x), "12:34.9"
      end
      it "converts 83.444 into '1:23.4'." do
        x = 1*60 + 23.444
        assert_eq x, 83.444
        assert_eq hhmmss(x), "1:23.4"
      end
      it "converts 56.8888 into '56.9'." do
        x = 56.8888
        assert_eq hhmmss(x), "56.9"
      end
      it "converts 9.777 into '9.78'." do
        x = 9.777
        assert_eq hhmmss(x), "9.78"
      end
      it "converts 0.7777 into '0.778'." do
        x = 0.7777
        assert_eq hhmmss(x), "0.778"
      end
    end

  end

end


