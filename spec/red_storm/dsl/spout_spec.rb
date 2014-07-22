require 'spec_helper'
require 'red_storm/dsl/spout'

describe RedStorm::SimpleSpout do

  before(:each) do
    Object.send(:remove_const, "Spout1") if Object.const_defined?("Spout1")
    Object.send(:remove_const, "Spout2") if Object.const_defined?("Spout2")
    Object.send(:remove_const, "Spout3") if Object.const_defined?("Spout3")
    Object.send(:remove_const, "Spout4") if Object.const_defined?("Spout4")
  end

  describe "interface" do
    it "should implement spout proxy" do
      spout = RedStorm::SimpleSpout.new
      spout.should respond_to :next_tuple
      spout.should respond_to :open
      spout.should respond_to :close
      spout.should respond_to :activate
      spout.should respond_to :deactivate
      spout.should respond_to :close
      spout.should respond_to :get_component_configuration
      spout.should respond_to :declare_output_fields
      spout.should respond_to :ack
      spout.should respond_to :fail
    end

    it "should implement dsl class statement" do
      RedStorm::SimpleSpout.should respond_to :configure
      RedStorm::SimpleSpout.should respond_to :output_fields
      RedStorm::SimpleSpout.should respond_to :on_init
      RedStorm::SimpleSpout.should respond_to :on_close
      RedStorm::SimpleSpout.should respond_to :on_activate
      RedStorm::SimpleSpout.should respond_to :on_deactivate
      RedStorm::SimpleSpout.should respond_to :on_send
      RedStorm::SimpleSpout.should respond_to :on_ack
      RedStorm::SimpleSpout.should respond_to :on_fail
      RedStorm::SimpleSpout.should respond_to :log
    end

    it "should implement dsl instance statements" do
      spout = RedStorm::SimpleSpout.new
      spout.should respond_to :emit
      spout.should respond_to :log
    end

  end

  describe "dsl" do

    describe "set statement" do
      DEFAULT_SPOUT_OPTIONS = {}

      # it "should parse options" do
      #   class IsDistributedClass < RedStorm::SimpleSpout
      #     set :is_distributed => true
      #   end
      #   IsDistributedClass.send(:spout_options).should == DEFAULT_SPOUT_OPTIONS.merge(:is_distributed => true)
      #   IsDistributedClass.send(:is_distributed?).should be_true
      # end
    end

    describe "output_field statement" do
      it "should parse single argument" do
        class Spout1 < RedStorm::SimpleSpout
          output_fields :f1
        end
        Spout1.send(:fields).should == ["f1"]
      end

      it "should parse multiple arguments" do
        class Spout1 < RedStorm::SimpleSpout
          output_fields :f1, :f2
        end
        Spout1.send(:fields).should == ["f1", "f2"]
      end

      it "should parse string and symbol arguments" do
        class Spout1 < RedStorm::SimpleSpout
          output_fields :f1, "f2"
        end
        Spout1.send(:fields).should == ["f1", "f2"]
      end

      it "should not share state over mutiple classes" do
        class Spout1 < RedStorm::SimpleSpout
          output_fields :f1
        end
        class Spout2 < RedStorm::SimpleSpout
          output_fields :f2
        end
        RedStorm::SimpleSpout.send(:fields).should == []
        Spout1.send(:fields).should == ["f1"]
        Spout2.send(:fields).should == ["f2"]
      end
    end

    describe "on_send statement" do
      DEFAULT_SEND_OPTIONS = {:emit => true, :reliable => false}

      it "should emit by defaut" do
        RedStorm::SimpleSpout.send(:emit?).should be_true
      end

      describe "with block argument" do

        it "should parse without options" do
          class Spout1 < RedStorm::SimpleSpout
            on_send {self.test_method}
          end

          Spout1.send_options.should == DEFAULT_SEND_OPTIONS

          spout = Spout1.new
          spout.should_receive(:test_method)
          Spout1.should_receive(:emit?).and_return(false)
          spout.next_tuple
        end

        it "should parse :emit option" do
          class Spout1 < RedStorm::SimpleSpout
            on_send :emit => false do
              self.test_method
            end
          end

          Spout1.send_options.should == DEFAULT_SEND_OPTIONS.merge(:emit => false)
          Spout1.send(:emit?).should be_false

          spout = Spout1.new
          spout.should_receive(:test_method)
          spout.next_tuple
        end
      end

      describe "with method name" do

        it "should parse without options" do
          class Spout1 < RedStorm::SimpleSpout
            on_send :test_method
          end

          Spout1.send_options.should == DEFAULT_SEND_OPTIONS

          spout = Spout1.new
          spout.should_receive(:test_method)
          Spout1.should_receive(:emit?).and_return(false)
          spout.next_tuple
        end

        it "should parse :emit option" do
          class Spout1 < RedStorm::SimpleSpout
            on_send :test_method, :emit => false
          end

          Spout1.send_options.should == DEFAULT_SEND_OPTIONS.merge(:emit => false)
          Spout1.send(:emit?).should be_false

          spout = Spout1.new
          spout.should_receive(:test_method)
          spout.next_tuple
        end
      end

      describe "with method" do

        it "should parse without options" do
          class Spout1 < RedStorm::SimpleSpout
            def on_send; test_method; end
          end

          Spout1.send_options.should == DEFAULT_SEND_OPTIONS

          spout = Spout1.new
          spout.should_receive(:test_method)
          Spout1.should_receive(:emit?).and_return(false)
          spout.next_tuple
        end

        it "should parse :emit option" do
          class Spout1 < RedStorm::SimpleSpout
            on_send :emit => false
            def on_send; test_method; end
          end

          Spout1.send_options.should == DEFAULT_SEND_OPTIONS.merge(:emit => false)
          Spout1.send(:emit?).should be_false

          spout = Spout1.new
          spout.should_receive(:test_method)
          spout.next_tuple
        end
      end
    end


    describe "on_init statement" do

      it "should parse block argument" do
        class Spout1 < RedStorm::SimpleSpout
          on_init {self.test_block_call}
        end

        spout = Spout1.new
        spout.should_receive(:test_block_call)
        spout.open(nil, nil, nil)
      end

      it "should parse method name" do
        class Spout1 < RedStorm::SimpleSpout
          on_init :test_method
        end

        spout = Spout1.new
        spout.should_receive(:test_method)
        spout.open(nil, nil, nil)
      end

      it "should call method" do
        class Spout1 < RedStorm::SimpleSpout
          def on_init; test_method; end
        end

        spout = Spout1.new
        spout.should_receive(:test_method)
        spout.open(nil, nil, nil)
      end
    end

    describe "on_close statement" do

      it "should parse block argument" do
        class Spout1 < RedStorm::SimpleSpout
          on_close {self.test_block_call}
        end

        spout = Spout1.new
        spout.should_receive(:test_block_call)
        spout.close
      end

      it "should parse method name" do
        class Spout1 < RedStorm::SimpleSpout
          on_close :test_method
        end

        spout = Spout1.new
        spout.should_receive(:test_method)
        spout.close
      end

      it "should call method" do
        class Spout1 < RedStorm::SimpleSpout
          def on_close; test_method; end
        end

        spout = Spout1.new
        spout.should_receive(:test_method)
        spout.close
      end
    end

    describe "on_ack statement" do

      it "should parse block argument" do
        class Spout1 < RedStorm::SimpleSpout
          on_ack {|msg_id| self.test_block_call(msg_id)}
        end

        spout = Spout1.new
        spout.should_receive(:test_block_call).with("test")
        spout.ack("test")
      end

      it "should parse method name" do
        class Spout1 < RedStorm::SimpleSpout
          on_ack :test_method
        end

        spout = Spout1.new
        spout.should_receive(:test_method).with("test")
        spout.ack("test")
      end

      it "should call method " do
        class Spout1 < RedStorm::SimpleSpout
          def on_ack(msg_id); test_method(msg_id); end
        end

        spout = Spout1.new
        spout.should_receive(:test_method).with("test")
        spout.ack("test")
      end
    end

    describe "on_fail statement" do

      it "should parse block argument" do
        class Spout1 < RedStorm::SimpleSpout
          on_fail {|msg_id| self.test_block_call(msg_id)}
        end

        spout = Spout1.new
        spout.should_receive(:test_block_call).with("test")
        spout.fail("test")
      end

      it "should parse method name" do
        class Spout1 < RedStorm::SimpleSpout
          on_fail :test_method
        end

        spout = Spout1.new
        spout.should_receive(:test_method).with("test")
        spout.fail("test")
      end

      it "should parse method name" do
        class Spout1 < RedStorm::SimpleSpout
          def on_fail(msg_id); test_method(msg_id); end
        end

        spout = Spout1.new
        spout.should_receive(:test_method).with("test")
        spout.fail("test")
      end
    end

    describe "on_activate statement" do

      it "should parse block argument" do
        class Spout1 < RedStorm::SimpleSpout
          on_activate {self.test_block_call}
        end

        spout = Spout1.new
        spout.should_receive(:test_block_call)
        spout.activate
      end

      it "should parse method name" do
        class Spout1 < RedStorm::SimpleSpout
          on_activate :test_method
        end

        spout = Spout1.new
        spout.should_receive(:test_method)
        spout.activate
      end

      it "should parse method name" do
        class Spout1 < RedStorm::SimpleSpout
          def on_activate; test_method; end
        end

        spout = Spout1.new
        spout.should_receive(:test_method)
        spout.activate
      end
    end

   describe "on_deactivate statement" do

      it "should parse block argument" do
        class Spout1 < RedStorm::SimpleSpout
          on_deactivate {self.test_block_call}
        end

        spout = Spout1.new
        spout.should_receive(:test_block_call)
        spout.deactivate
      end

      it "should parse method name" do
        class Spout1 < RedStorm::SimpleSpout
          on_deactivate :test_method
        end

        spout = Spout1.new
        spout.should_receive(:test_method)
        spout.deactivate
      end

      it "should parse method name" do
        class Spout1 < RedStorm::SimpleSpout
          def on_deactivate; test_method; end
        end

        spout = Spout1.new
        spout.should_receive(:test_method)
        spout.deactivate
      end
    end

    describe "configure statement" do

      it "should parse configuration block" do
        class Spout1 < RedStorm::SimpleSpout
          configure {trigger}
        end
        spout = Spout1.new
        spout.should_receive(:trigger)
        spout.instance_exec(&Spout1.configure_block)
      end
    end


    # log specs are mostly the same ats in the bolt specs. if these are modified, sync with bolt
    describe "log statement" do

      module Java::OrgSlf4j end;
      class Java::OrgSlf4j::Logger; end
      class Java::OrgSlf4j::LoggerFactory; end

      describe "in class" do
        it "should proxy to storm slf4j logger" do
          logger = mock(Java::OrgSlf4j::Logger)
          Java::OrgSlf4j::LoggerFactory.should_receive("get_logger").with("Spout1").and_return(logger)
          logger.should_receive(:info).with("test")

          class Spout1 < RedStorm::SimpleSpout
            log.info("test")
          end
        end

        it "should use own class name as logger id" do
          logger1 = mock(Java::OrgSlf4j::Logger)
          logger2 = mock(Java::OrgSlf4j::Logger)
          Java::OrgSlf4j::LoggerFactory.should_receive("get_logger").with("Spout1").and_return(logger1)
          Java::OrgSlf4j::LoggerFactory.should_receive("get_logger").with("Spout2").and_return(logger2)
          logger1.should_receive(:info).with("test1")
          logger2.should_receive(:info).with("test2")

          class Spout1 < RedStorm::SimpleSpout
            log.info("test1")
          end
          class Spout2 < RedStorm::SimpleSpout
            log.info("test2")
          end
        end
      end

      describe "in instance" do
        it "should proxy to storm slf4j logger" do
          logger = mock(Java::OrgSlf4j::Logger)
          Java::OrgSlf4j::LoggerFactory.should_receive("get_logger").with("Spout1").and_return(logger)

          class Spout1 < RedStorm::SimpleSpout
            on_init {log.info("test")}
          end

          logger.should_receive(:info).with("test")
          spout = Spout1.new
          spout.open(nil, nil, nil)
        end

        it "should use own class name as logger id" do
          logger1 = mock(Java::OrgSlf4j::Logger)
          logger2 = mock(Java::OrgSlf4j::Logger)
          Java::OrgSlf4j::LoggerFactory.should_receive("get_logger").with("Spout1").and_return(logger1)
          Java::OrgSlf4j::LoggerFactory.should_receive("get_logger").with("Spout2").and_return(logger2)

          class Spout1 < RedStorm::SimpleSpout
            on_init {log.info("test1")}
          end
          class Spout2 < RedStorm::SimpleSpout
            on_init {log.info("test2")}
          end

          logger1.should_receive(:info).with("test1")
          spout1 = Spout1.new
          spout1.open(nil, nil, nil)

          logger2.should_receive(:info).with("test2")
          spout2 = Spout2.new
          spout2.open(nil, nil, nil)
        end

        it "should conform to SLF4J Named Hierarchy when loading loggers" do
          logger = mock(Java::OrgSlf4j::Logger)
          Java::OrgSlf4j::LoggerFactory.should_receive("get_logger").with("Named.Hierarchy.Spout").and_return(logger)
          module Named
            module Hierarchy
              class Spout < RedStorm::SimpleSpout
                on_init {log.info("test1")}
              end
            end
          end

          logger.should_receive(:info).with("test1")
          spout = Named::Hierarchy::Spout.new
          spout.open(nil, nil, nil)
        end
      end
    end
  end

  describe "spout" do

    class RedStorm::Values; end

    describe "next_tuple" do

      it "should auto unreliable emit on single value output" do
        class Spout1 < RedStorm::SimpleSpout
          on_send {"output"}
        end
        class Spout2 < RedStorm::SimpleSpout
          on_send :my_method
          def my_method; "output"; end
        end
        class Spout3 < RedStorm::SimpleSpout
          def on_send; "output"; end
        end

        collector = mock("Collector")
        RedStorm::Values.should_receive(:new).with("output").exactly(3).times.and_return("values")
        collector.should_receive(:emit).with("values").exactly(3).times

        spout = Spout1.new
        spout.open(nil, nil, collector)
        spout.next_tuple

        spout = Spout2.new
        spout.open(nil, nil, collector)
        spout.next_tuple

        spout = Spout3.new
        spout.open(nil, nil, collector)
        spout.next_tuple
      end

      it "should auto reliable emit on single value output" do
        class Spout1 < RedStorm::SimpleSpout
          on_send :reliable => true do
            [1, "output"]
          end
        end
        class Spout2 < RedStorm::SimpleSpout
          on_send :my_method, :reliable => true
          def my_method; [2, "output"]; end
        end
        class Spout3 < RedStorm::SimpleSpout
          on_send :reliable => true
          def on_send; [3, "output"] end
        end

        collector = mock("Collector")
        RedStorm::Values.should_receive(:new).with("output").exactly(3).times.and_return("values")
        collector.should_receive(:emit).with("values", 1).once
        collector.should_receive(:emit).with("values", 2).once
        collector.should_receive(:emit).with("values", 3).once

        spout = Spout1.new
        spout.open(nil, nil, collector)
        spout.next_tuple

        spout = Spout2.new
        spout.open(nil, nil, collector)
        spout.next_tuple

        spout = Spout3.new
        spout.open(nil, nil, collector)
        spout.next_tuple
      end

      it "should auto unreliable emit on multiple values output" do
        class Spout1 < RedStorm::SimpleSpout
          on_send {["output1", "output2"]}
        end
        class Spout2 < RedStorm::SimpleSpout
          on_send :my_method
          def my_method; ["output1", "output2"]; end
        end
        class Spout3 < RedStorm::SimpleSpout
          def on_send; ["output1", "output2"]; end
        end

        collector = mock("Collector")
        RedStorm::Values.should_receive(:new).with("output1", "output2").exactly(3).times.and_return("values")
        collector.should_receive(:emit).with("values").exactly(3).times

        spout = Spout1.new
        spout.open(nil, nil, collector)
        spout.next_tuple

        spout = Spout2.new
        spout.open(nil, nil, collector)
        spout.next_tuple

        spout = Spout3.new
        spout.open(nil, nil, collector)
        spout.next_tuple
      end

      it "should auto reliable emit on multiple values output" do
        class Spout1 < RedStorm::SimpleSpout
          on_send :reliable => true do
            [1, "output1", "output2"]
          end
        end
        class Spout2 < RedStorm::SimpleSpout
          on_send :my_method, :reliable => true
          def my_method; [2, "output1", "output2"]; end
        end
        class Spout3 < RedStorm::SimpleSpout
          on_send :reliable => true
          def on_send; [3, "output1", "output2"] end
        end

        collector = mock("Collector")
        RedStorm::Values.should_receive(:new).with("output1", "output2").exactly(3).times.and_return("values")
        collector.should_receive(:emit).with("values", 1).once
        collector.should_receive(:emit).with("values", 2).once
        collector.should_receive(:emit).with("values", 3).once

        spout = Spout1.new
        spout.open(nil, nil, collector)
        spout.next_tuple

        spout = Spout2.new
        spout.open(nil, nil, collector)
        spout.next_tuple

        spout = Spout3.new
        spout.open(nil, nil, collector)
        spout.next_tuple
      end

      it "should sleep on nil output" do
        class Spout1 < RedStorm::SimpleSpout
          on_send {nil}
        end
        class Spout2 < RedStorm::SimpleSpout
          on_send :my_method
          def my_method; nil; end
        end
        class Spout3 < RedStorm::SimpleSpout
          def on_send; nil; end
        end

        collector = mock("Collector")
        RedStorm::Values.should_receive(:new).never
        collector.should_receive(:emit).never

        spout = Spout1.new
        spout.should_receive(:sleep)
        spout.open(nil, nil, collector)
        spout.next_tuple

        spout = Spout2.new
        spout.should_receive(:sleep)
        spout.open(nil, nil, collector)
        spout.next_tuple

        spout = Spout3.new
        spout.should_receive(:sleep)
        spout.open(nil, nil, collector)
        spout.next_tuple
      end

      it "should respect :emit => false" do
        class Spout1 < RedStorm::SimpleSpout
          on_send :emit => false do
            "output"
          end
        end
        class Spout2 < RedStorm::SimpleSpout
          on_send :my_method, :emit => false
          def my_method; "output"; end
        end
        class Spout3 < RedStorm::SimpleSpout
          on_send :emit => false
          def on_send; "output" end
        end

        collector = mock("Collector")
        RedStorm::Values.should_receive(:new).never
        collector.should_receive(:emit).never

        spout = Spout1.new
        spout.should_receive(:sleep).never
        spout.open(nil, nil, collector)
        spout.next_tuple

        spout = Spout2.new
        spout.should_receive(:sleep).never
        spout.open(nil, nil, collector)
        spout.next_tuple

        spout = Spout3.new
        spout.should_receive(:sleep).never
        spout.open(nil, nil, collector)
        spout.next_tuple
      end

      it "should support manual emit" do
        class Spout1 < RedStorm::SimpleSpout
          on_send :emit => false do
            reliable_emit 1, "reliable output"
          end
        end
        class Spout2 < RedStorm::SimpleSpout
          on_send :emit => false do
            unreliable_emit "unreliable output"
          end
        end

        collector = mock("Collector")
        RedStorm::Values.should_receive(:new).once.with("reliable output").and_return("reliable values")
        RedStorm::Values.should_receive(:new).once.with("unreliable output").and_return("unreliable values")
        collector.should_receive(:emit).with("unreliable values").once
        collector.should_receive(:emit).with("reliable values", 1).once

        spout = Spout1.new
        spout.should_receive(:sleep).never
        spout.open(nil, nil, collector)
        spout.next_tuple

        spout = Spout2.new
        spout.should_receive(:sleep).never
        spout.open(nil, nil, collector)
        spout.next_tuple
      end
    end

    describe "open" do
      it "should assing collector, context, config and call init block" do
        class Spout1 < RedStorm::SimpleSpout
          on_init {trigger}
        end
        class Spout2 < RedStorm::SimpleSpout
          on_init :my_method
          def my_method; trigger; end
        end
        class Spout3 < RedStorm::SimpleSpout
          def on_init; trigger; end
        end

        spout = Spout1.new
        spout.should_receive(:trigger).once
        spout.config.should be_nil
        spout.context.should be_nil
        spout.collector.should be_nil
        spout.open("config", "context", "collector")
        spout.config.should == "config"
        spout.context.should == "context"
        spout.collector.should == "collector"

        spout = Spout2.new
        spout.should_receive(:trigger).once
        spout.config.should be_nil
        spout.context.should be_nil
        spout.collector.should be_nil
        spout.open("config", "context", "collector")
        spout.config.should == "config"
        spout.context.should == "context"
        spout.collector.should == "collector"

        spout = Spout3.new
        spout.should_receive(:trigger).once
        spout.config.should be_nil
        spout.context.should be_nil
        spout.collector.should be_nil
        spout.open("config", "context", "collector")
        spout.config.should == "config"
        spout.context.should == "context"
        spout.collector.should == "collector"
      end
    end

    describe "close" do
      it "should call close block" do
        class Spout1 < RedStorm::SimpleSpout
          on_close {trigger}
        end
        class Spout2 < RedStorm::SimpleSpout
          on_close :my_method
          def my_method; trigger; end
        end
        class Spout3 < RedStorm::SimpleSpout
          def on_close; trigger; end
        end

        spout = Spout1.new
        spout.should_receive(:trigger).once
        spout.close

        spout = Spout2.new
        spout.should_receive(:trigger).once
        spout.close

        spout = Spout2.new
        spout.should_receive(:trigger).once
        spout.close
      end
    end

    describe "declare_output_fields" do
      it "should declare fields" do
        class Spout1 < RedStorm::SimpleSpout
          output_fields :f1, :f2
        end
        spout = Spout1.new
        class RedStorm::Fields; end
        declarer = mock("Declarer")
        declarer.should_receive(:declare).with("fields")
        RedStorm::Fields.should_receive(:new).with(["f1", "f2"]).and_return("fields")
        spout.declare_output_fields(declarer)
      end
    end

    # describe "is_distributed" do
    #   it "should report is_distributed" do
    #     RedStorm::SimpleSpout.is_distributed?.should be_false
    #     class Spout1 < RedStorm::SimpleSpout
    #       set :is_distributed => true
    #     end
    #     spout = Spout1.new
    #     spout.is_distributed.should be_true
    #   end
    # end

    describe "ack" do
      it "should call ack block" do
        class Spout1 < RedStorm::SimpleSpout
          on_ack {|msg_id| trigger(msg_id)}
        end
        class Spout2 < RedStorm::SimpleSpout
          on_ack :my_method
          def my_method(msg_id) trigger(msg_id); end
        end
        class Spout3 < RedStorm::SimpleSpout
          def on_ack(msg_id) trigger(msg_id); end
        end
        class Spout4 < RedStorm::SimpleSpout
        end

        spout = Spout1.new
        spout.should_receive(:trigger).once.with("test")
        spout.ack("test")

        spout = Spout2.new
        spout.should_receive(:trigger).once.with("test")
        spout.ack("test")

        spout = Spout3.new
        spout.should_receive(:trigger).once.with("test")
        spout.ack("test")

        spout = Spout4.new
        spout.should respond_to :ack
        spout.ack("test")
      end
    end

    describe "fail" do
      it "should call fail block" do
        class Spout1 < RedStorm::SimpleSpout
          on_fail {|msg_id| trigger(msg_id)}
        end
        class Spout2 < RedStorm::SimpleSpout
          on_fail :my_method
          def my_method(msg_id) trigger(msg_id); end
        end
        class Spout3 < RedStorm::SimpleSpout
          def on_fail(msg_id) trigger(msg_id); end
        end
        class Spout4 < RedStorm::SimpleSpout
        end

        spout = Spout1.new
        spout.should_receive(:trigger).once.with("test")
        spout.fail("test")

        spout = Spout2.new
        spout.should_receive(:trigger).once.with("test")
        spout.fail("test")

        spout = Spout3.new
        spout.should_receive(:trigger).once.with("test")
        spout.fail("test")

        spout = Spout4.new
        spout.should respond_to :fail
        spout.fail("test")
      end
    end

    describe "get_component_configuration" do

      it "should return Backtype::Config object" do
        class Spout1 < RedStorm::SimpleSpout; end
        spout = Spout1.new
        spout.get_component_configuration.should be_instance_of(Backtype::Config)
      end
    end
  end
end
