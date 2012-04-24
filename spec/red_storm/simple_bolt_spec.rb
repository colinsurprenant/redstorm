require 'spec_helper'
require 'red_storm/simple_bolt'

describe RedStorm::SimpleBolt do

  before(:each) do
    Object.send(:remove_const, "Bolt1") if Object.const_defined?("Bolt1")
    Object.send(:remove_const, "Bolt2") if Object.const_defined?("Bolt2")
    Object.send(:remove_const, "Bolt3") if Object.const_defined?("Bolt3")
  end

  describe "interface" do
    it "should implement bolt proxy" do
      bolt = RedStorm::SimpleBolt.new
      bolt.should respond_to :execute
      bolt.should respond_to :cleanup
      bolt.should respond_to :prepare
      bolt.should respond_to :declare_output_fields
    end

    it "should implement dsl class statements" do
      RedStorm::SimpleBolt.should respond_to :output_fields
      RedStorm::SimpleBolt.should respond_to :on_init
      RedStorm::SimpleBolt.should respond_to :on_close
      RedStorm::SimpleBolt.should respond_to :on_receive
      RedStorm::SimpleBolt.should respond_to :log
    end

    it "should implement dsl instance statements" do
      bolt = RedStorm::SimpleBolt.new
      bolt.should respond_to :unanchored_emit
      bolt.should respond_to :anchored_emit
      bolt.should respond_to :ack
      bolt.should respond_to :log
    end
  end

  describe "dsl" do

    describe "output_field statement" do
      it "should parse single argument" do
        class Bolt1 < RedStorm::SimpleBolt
          output_fields :f1
        end
        bolt = Bolt1.new
        Bolt1.send(:fields).should == ["f1"]
      end

      it "should parse multiple arguments" do
        class Bolt1 < RedStorm::SimpleBolt
          output_fields :f1, :f2
        end
        Bolt1.send(:fields).should == ["f1", "f2"]
      end

      it "should parse string and symbol arguments" do
        class Bolt1 < RedStorm::SimpleBolt
          output_fields :f1, "f2"
        end
        Bolt1.send(:fields).should == ["f1", "f2"]
      end

      it "should not share state over mutiple classes" do
        class Bolt1 < RedStorm::SimpleBolt
          output_fields :f1
        end
        class Bolt2 < RedStorm::SimpleBolt
          output_fields :f2
        end
        RedStorm::SimpleBolt.send(:fields).should == []
        Bolt1.send(:fields).should == ["f1"]
        Bolt2.send(:fields).should == ["f2"]
      end
    end

    describe "on_receive statement" do
      DEFAULT_RECEIVE_OPTIONS = {:emit => true, :ack => false, :anchor => false}

      it "should emit by defaut" do
        RedStorm::SimpleBolt.send(:emit?).should be_true
      end

      it "should not ack by defaut" do
        RedStorm::SimpleBolt.send(:ack?).should be_false
      end

      it "should not anchor by defaut" do
        RedStorm::SimpleBolt.send(:anchor?).should be_false
      end

      describe "with block argument" do

        it "should parse without options" do
          class Bolt1 < RedStorm::SimpleBolt
            on_receive {}
          end

          Bolt1.receive_options.should == DEFAULT_RECEIVE_OPTIONS
          Bolt1.send(:emit?).should be_true
          Bolt1.send(:ack?).should be_false
          Bolt1.send(:anchor?).should be_false
        end

        it "should parse :emit option" do
          class Bolt1 < RedStorm::SimpleBolt
            on_receive :emit => false do
            end
          end

          Bolt1.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:emit => false)
          Bolt1.send(:emit?).should be_false
        end

        it "should parse :ack option" do
          class Bolt1 < RedStorm::SimpleBolt
            on_receive :ack => true do
            end
          end

          Bolt1.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:ack => true)
          Bolt1.send(:ack?).should be_true
        end

        it "should parse :anchor option" do
          class Bolt1 < RedStorm::SimpleBolt
            on_receive :anchor => true do
            end
          end

          Bolt1.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:anchor => true)
          Bolt1.send(:anchor?).should be_true
        end

        it "should parse multiple option" do
          class Bolt1 < RedStorm::SimpleBolt
            on_receive :emit => false, :ack =>true, :anchor => true do
            end
          end

          Bolt1.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:emit =>false, :ack => true, :anchor => true)
          Bolt1.send(:emit?).should be_false
          Bolt1.send(:ack?).should be_true
          Bolt1.send(:anchor?).should be_true
        end
      end

      describe "with method name" do

        it "should parse without options" do
          class Bolt1 < RedStorm::SimpleBolt
            on_receive :test_method
          end

          Bolt1.receive_options.should == DEFAULT_RECEIVE_OPTIONS
          Bolt1.send(:emit?).should be_true
          Bolt1.send(:ack?).should be_false
          Bolt1.send(:anchor?).should be_false
        end

        it "should parse :emit option" do
          class Bolt1 < RedStorm::SimpleBolt
            on_receive :test_method, :emit => false
          end

          Bolt1.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:emit => false)
          Bolt1.send(:emit?).should be_false
        end

        it "should parse :ack option" do
          class Bolt1 < RedStorm::SimpleBolt
            on_receive :ack => true do
            end
          end

          Bolt1.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:ack => true)
          Bolt1.send(:ack?).should be_true
        end

        it "should parse :anchor option" do
          class Bolt1 < RedStorm::SimpleBolt
            on_receive :anchor => true do
            end
          end

          Bolt1.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:anchor => true)
          Bolt1.send(:anchor?).should be_true
        end

        it "should parse multiple option" do
          class Bolt1 < RedStorm::SimpleBolt
            on_receive :emit => false, :ack =>true, :anchor => true do
            end
          end

          Bolt1.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:emit =>false, :ack => true, :anchor => true)
          Bolt1.send(:emit?).should be_false
          Bolt1.send(:ack?).should be_true
          Bolt1.send(:anchor?).should be_true
        end
      end

      describe "with default method" do

        it "should parse without options" do
          class Bolt1 < RedStorm::SimpleBolt
          end

          Bolt1.receive_options.should == DEFAULT_RECEIVE_OPTIONS
          Bolt1.send(:emit?).should be_true
          Bolt1.send(:ack?).should be_false
          Bolt1.send(:anchor?).should be_false
        end

        it "should parse :emit option" do
          class Bolt1 < RedStorm::SimpleBolt
            on_receive :emit => false
          end

          Bolt1.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:emit => false)
          Bolt1.send(:emit?).should be_false
        end

        it "should parse :ack option" do
          class Bolt1 < RedStorm::SimpleBolt
            on_receive :ack => true
          end

          Bolt1.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:ack => true)
          Bolt1.send(:ack?).should be_true
        end

        it "should parse :anchor option" do
          class Bolt1 < RedStorm::SimpleBolt
            on_receive :anchor => true
          end

          Bolt1.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:anchor => true)
          Bolt1.send(:anchor?).should be_true
        end

        it "should parse multiple option" do
          class Bolt1 < RedStorm::SimpleBolt
            on_receive :emit => false, :ack =>true, :anchor => true
          end

          Bolt1.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:emit =>false, :ack => true, :anchor => true)
          Bolt1.send(:emit?).should be_false
          Bolt1.send(:ack?).should be_true
          Bolt1.send(:anchor?).should be_true
        end
      end
    end

    describe "on_init statement" do

      it "should parse block argument" do
        class Bolt1 < RedStorm::SimpleBolt
          on_init {self.test_block_call}
        end

        bolt = Bolt1.new
        bolt.should_receive(:test_block_call)
        bolt.prepare(nil, nil, nil)
      end

      it "should parse method name" do
        class Bolt1 < RedStorm::SimpleBolt
          on_init :test_method
        end

        bolt = Bolt1.new
        bolt.should_receive(:test_method)
        bolt.prepare(nil, nil, nil)
      end
    end

    describe "on_close statement" do

      it "should parse block argument" do
        class Bolt1 < RedStorm::SimpleBolt
          on_close {self.test_block_call}
        end

        bolt = Bolt1.new
        bolt.should_receive(:test_block_call)
        bolt.cleanup
      end

      it "should parse method name" do
        class Bolt1 < RedStorm::SimpleBolt
          on_close :test_method
        end

        bolt = Bolt1.new
        bolt.should_receive(:test_method)
        bolt.cleanup
      end
    end

    # log specs are mostly the same ats in the spout specs. if these are modified, sync with spout
    describe "log statement" do

      class Logger; end # mock log4j Logger class which does not exists in the specs context

      describe "in class" do
        it "should proxy to storm log4j logger" do
          logger = mock(Logger)
          Logger.should_receive("getLogger").with("Bolt1").and_return(logger)
          logger.should_receive(:info).with("test")

          class Bolt1 < RedStorm::SimpleBolt
            log.info("test")
          end
        end

        it "should use own class name as logger id" do
          logger1 = mock(Logger)
          logger2 = mock(Logger)
          Logger.should_receive("getLogger").with("Bolt1").and_return(logger1)
          Logger.should_receive("getLogger").with("Bolt2").and_return(logger2)
          logger1.should_receive(:info).with("test1")
          logger2.should_receive(:info).with("test2")

          class Bolt1 < RedStorm::SimpleBolt
            log.info("test1")
          end
          class Bolt2 < RedStorm::SimpleBolt
            log.info("test2")
          end
        end
      end

      describe "in instance" do
        it "should proxy to storm log4j logger" do
          logger = mock(Logger)
          Logger.should_receive("getLogger").with("Bolt1").and_return(logger)

          class Bolt1 < RedStorm::SimpleBolt
            on_init {log.info("test")}
          end

          logger.should_receive(:info).with("test")
          bolt = Bolt1.new
          bolt.prepare(nil, nil, nil)
        end

        it "should use own class name as logger id" do
          logger1 = mock(Logger)
          logger2 = mock(Logger)
          Logger.should_receive("getLogger").with("Bolt1").and_return(logger1)
          Logger.should_receive("getLogger").with("Bolt2").and_return(logger2)

          class Bolt1 < RedStorm::SimpleBolt
            on_init {log.info("test1")}
          end
          class Bolt2 < RedStorm::SimpleBolt
            on_init {log.info("test2")}
          end

          logger1.should_receive(:info).with("test1")
          bolt1 = Bolt1.new
          bolt1.prepare(nil, nil, nil)

          logger2.should_receive(:info).with("test2")
          bolt2 = Bolt2.new
          bolt2.prepare(nil, nil, nil)
        end
      end
    end
  end

  describe "bolt" do

    describe "execute" do

      class RedStorm::Values; end

      it "should auto emit on single value output" do
        class Bolt1 < RedStorm::SimpleBolt
          on_receive {|tuple| tuple}
        end
        class Bolt2 < RedStorm::SimpleBolt
          on_receive :my_method
          def my_method(tuple); tuple; end
        end
        class Bolt3 < RedStorm::SimpleBolt
          def on_receive(tuple); tuple; end
        end

        collector = mock("Collector")
        RedStorm::Values.should_receive(:new).with("output").exactly(3).times.and_return("values")
        collector.should_receive(:emit).with("values").exactly(3).times

        bolt = Bolt1.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("output")

        bolt = Bolt2.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("output")

        bolt = Bolt3.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("output")
      end

      it "should auto emit on single multiple-value output" do
        class Bolt1 < RedStorm::SimpleBolt
          on_receive {|tuple| tuple}
        end
        class Bolt2 < RedStorm::SimpleBolt
          on_receive :my_method
          def my_method(tuple); tuple; end
        end
        class Bolt3 < RedStorm::SimpleBolt
          def on_receive(tuple); tuple; end
        end

        collector = mock("Collector")
        RedStorm::Values.should_receive(:new).with("output1", "output2").exactly(3).times.and_return("values")
        collector.should_receive(:emit).with("values").exactly(3).times

        bolt = Bolt1.new
        bolt.prepare(nil, nil, collector)
        bolt.execute(["output1", "output2"])

        bolt = Bolt2.new
        bolt.prepare(nil, nil, collector)
        bolt.execute(["output1", "output2"])

        bolt = Bolt3.new
        bolt.prepare(nil, nil, collector)
        bolt.execute(["output1", "output2"])
      end

      it "should auto emit on multiple multiple-value output" do
        class Bolt1 < RedStorm::SimpleBolt
          on_receive {|tuple| tuple}
        end
        class Bolt2 < RedStorm::SimpleBolt
          on_receive :my_method
          def my_method(tuple); tuple; end
        end
        class Bolt3 < RedStorm::SimpleBolt
          def on_receive(tuple); tuple; end
        end

        collector = mock("Collector")
        RedStorm::Values.should_receive(:new).with("output1", "output2").exactly(3).times.and_return("values1")
        RedStorm::Values.should_receive(:new).with("output3", "output4").exactly(3).times.and_return("values2")
        collector.should_receive(:emit).with("values1").exactly(3).times
        collector.should_receive(:emit).with("values2").exactly(3).times

        bolt = Bolt1.new
        bolt.prepare(nil, nil, collector)
        bolt.execute([["output1", "output2"], ["output3", "output4"]])

        bolt = Bolt2.new
        bolt.prepare(nil, nil, collector)
        bolt.execute([["output1", "output2"], ["output3", "output4"]])

        bolt = Bolt3.new
        bolt.prepare(nil, nil, collector)
        bolt.execute([["output1", "output2"], ["output3", "output4"]])
      end

      it "should anchor on single value output" do
        class Bolt1 < RedStorm::SimpleBolt
          on_receive :anchor => true do |tuple| 
            "output"
          end
        end
        class Bolt2 < RedStorm::SimpleBolt
          on_receive :my_method, :anchor => true 
          def my_method(tuple) 
            "output"
          end
        end
        class Bolt3 < RedStorm::SimpleBolt
          on_receive :anchor => true 
          def on_receive(tuple) 
            "output"
          end
        end

        collector = mock("Collector")
        RedStorm::Values.should_receive(:new).with("output").exactly(3).times.and_return("values")
        collector.should_receive(:emit).with("tuple", "values").exactly(3).times

        bolt = Bolt1.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("tuple")

        bolt = Bolt2.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("tuple")

        bolt = Bolt3.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("tuple")
      end

      it "should ack on single value output" do
        class Bolt1 < RedStorm::SimpleBolt
          on_receive :anchor => true, :ack => true do |tuple| 
            "output"
          end
        end
        class Bolt2 < RedStorm::SimpleBolt
          on_receive :my_method, :anchor => true, :ack => true
          def my_method(tuple) 
            "output"
          end
        end
        class Bolt3 < RedStorm::SimpleBolt
          on_receive :anchor => true, :ack => true 
          def on_receive(tuple) 
            "output"
          end
        end

        collector = mock("Collector")
        RedStorm::Values.should_receive(:new).with("output").exactly(3).times.and_return("values")
        collector.should_receive(:emit).with("tuple", "values").exactly(3).times
        collector.should_receive(:ack).with("tuple").exactly(3).times

        bolt = Bolt1.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("tuple")

        bolt = Bolt2.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("tuple")

        bolt = Bolt3.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("tuple")
      end

      it "should not emit" do
        class Bolt1 < RedStorm::SimpleBolt
          on_receive :emit => false do |tuple| 
            tuple
          end
        end
        class Bolt2 < RedStorm::SimpleBolt
          on_receive :my_method, :emit => false
          def my_method(tuple)
            tuple
          end
        end
        class Bolt3 < RedStorm::SimpleBolt
          on_receive :emit => false
          def on_receive(tuple) 
            tuple
          end
        end

        collector = mock("Collector")
        RedStorm::Values.should_receive(:new).never
        collector.should_receive(:emit).never

        bolt = Bolt1.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("output")

        bolt = Bolt2.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("output")

        bolt = Bolt3.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("output")
      end
    end

    describe "prepare" do
      it "should assing collector, context, config and call init block" do
        class Bolt1 < RedStorm::SimpleBolt
          on_init {trigger}
        end
        class Bolt2 < RedStorm::SimpleBolt
          on_init :my_method
          def my_method; trigger; end
        end
        class Bolt3 < RedStorm::SimpleBolt
          def on_init; trigger; end
        end

        bolt = Bolt1.new
        bolt.should_receive(:trigger).once
        bolt.config.should be_nil
        bolt.context.should be_nil
        bolt.collector.should be_nil
        bolt.prepare("config", "context", "collector")
        bolt.config.should == "config"
        bolt.context.should == "context"
        bolt.collector.should == "collector"

        bolt = Bolt2.new
        bolt.should_receive(:trigger).once
        bolt.config.should be_nil
        bolt.context.should be_nil
        bolt.collector.should be_nil
        bolt.prepare("config", "context", "collector")
        bolt.config.should == "config"
        bolt.context.should == "context"
        bolt.collector.should == "collector"

        bolt = Bolt3.new
        bolt.should_receive(:trigger).once
        bolt.config.should be_nil
        bolt.context.should be_nil
        bolt.collector.should be_nil
        bolt.prepare("config", "context", "collector")
        bolt.config.should == "config"
        bolt.context.should == "context"
        bolt.collector.should == "collector"
      end
    end

    describe "cleanup" do
      it "should call close block" do
        class Bolt1 < RedStorm::SimpleBolt
          on_close {trigger}
        end
        class Bolt2 < RedStorm::SimpleBolt
          on_close :my_method
          def my_method; trigger; end
        end
        class Bolt3 < RedStorm::SimpleBolt
          def on_close; trigger; end
        end

        bolt = Bolt1.new
        bolt.should_receive(:trigger).once
        bolt.cleanup

        bolt = Bolt2.new
        bolt.should_receive(:trigger).once
        bolt.cleanup

        bolt = Bolt3.new
        bolt.should_receive(:trigger).once
        bolt.cleanup
      end
    end

    describe "declare_output_fields" do
      it "should declare fields" do
        class Bolt1 < RedStorm::SimpleBolt
          output_fields :f1, :f2
        end
        bolt = Bolt1.new
        class RedStorm::Fields; end
        declarer = mock("Declarer")
        declarer.should_receive(:declare).with("fields")
        RedStorm::Fields.should_receive(:new).with(["f1", "f2"]).and_return("fields")
        bolt.declare_output_fields(declarer)
      end
    end

  end
end