require 'spec_helper'
require 'red_storm/environment'

describe RedStorm do

  describe "jruby_mode_token" do

    it "should default to current JRuby mode" do
      RedStorm.should_receive(:current_ruby_mode).and_return("1.8")
      RedStorm.jruby_mode_token.should == "RUBY1_8"

      RedStorm.should_receive(:current_ruby_mode).and_return("1.9")
      RedStorm.jruby_mode_token.should == "RUBY1_9"
    end

    it "should use provided version" do
      RedStorm.should_receive(:current_ruby_mode).never

      RedStorm.jruby_mode_token("1.8").should == "RUBY1_8"
      RedStorm.jruby_mode_token("--1.8").should == "RUBY1_8"

      RedStorm.jruby_mode_token("1.9").should == "RUBY1_9"
      RedStorm.jruby_mode_token("--1.9").should == "RUBY1_9"
    end

    it "should default to current JRuby mode on invalid version" do
      RedStorm.should_receive(:current_ruby_mode).and_return("1.9")
      RedStorm.jruby_mode_token("foobar").should == "RUBY1_9"
    end
  end
end
