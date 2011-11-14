require 'spec_helper'
require 'red_storm/simple_bolt'

describe RedStorm::SimpleBolt do

  describe "interface" do
    it "should implement bolt proxy" do
      spout = RedStorm::SimpleBolt.new
      spout.should respond_to :execute
      spout.should respond_to :cleanup
      spout.should respond_to :prepare
      spout.should respond_to :declare_output_fields
    end

    it "should implement dsl statement" do
      RedStorm::SimpleBolt.should respond_to :output_fields
      RedStorm::SimpleBolt.should respond_to :on_init
      RedStorm::SimpleBolt.should respond_to :on_close
      RedStorm::SimpleBolt.should respond_to :on_receive
    end
  end

  describe "dsl" do

    describe "output_field statement" do
      it "should parse single argument" do
        class BoltOutputField1 < RedStorm::SimpleBolt
          output_fields :f1
        end
        bolt = BoltOutputField1.new
        BoltOutputField1.send(:fields).should == ["f1"]
      end

      it "should parse multiple arguments" do
        class BoltOutputField2 < RedStorm::SimpleBolt
          output_fields :f1, :f2
        end
        BoltOutputField2.send(:fields).should == ["f1", "f2"]
      end

      it "should parse string and symbol arguments" do
        class BoltOutputField3 < RedStorm::SimpleBolt
          output_fields :f1, "f2"
        end
        BoltOutputField3.send(:fields).should == ["f1", "f2"]
      end

      it "should not share state over mutiple classes" do
        class BoltOutputField4 < RedStorm::SimpleBolt
          output_fields :f1
        end
        class BoltOutputField5 < RedStorm::SimpleBolt
          output_fields :f2
        end
        RedStorm::SimpleBolt.send(:fields).should == []
        BoltOutputField4.send(:fields).should == ["f1"]
        BoltOutputField5.send(:fields).should == ["f2"]
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
          class BoltBlockArgument1 < RedStorm::SimpleBolt
            on_receive {}
          end

          BoltBlockArgument1.receive_options.should == DEFAULT_RECEIVE_OPTIONS
          BoltBlockArgument1.send(:emit?).should be_true
          BoltBlockArgument1.send(:ack?).should be_false
          BoltBlockArgument1.send(:anchor?).should be_false
        end

        it "should parse :emit option" do
          class BoltBlockArgument2 < RedStorm::SimpleBolt
            on_receive :emit => false do
            end
          end

          BoltBlockArgument2.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:emit => false)
          BoltBlockArgument2.send(:emit?).should be_false
        end

        it "should parse :ack option" do
          class BoltBlockArgument3 < RedStorm::SimpleBolt
            on_receive :ack => true do
            end
          end

          BoltBlockArgument3.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:ack => true)
          BoltBlockArgument3.send(:ack?).should be_true
        end

        it "should parse :anchor option" do
          class BoltBlockArgument4 < RedStorm::SimpleBolt
            on_receive :anchor => true do
            end
          end

          BoltBlockArgument4.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:anchor => true)
          BoltBlockArgument4.send(:anchor?).should be_true
        end

        it "should parse multiple option" do
          class BoltBlockArgument5 < RedStorm::SimpleBolt
            on_receive :emit => false, :ack =>true, :anchor => true do
            end
          end

          BoltBlockArgument5.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:emit =>false, :ack => true, :anchor => true)
          BoltBlockArgument5.send(:emit?).should be_false
          BoltBlockArgument5.send(:ack?).should be_true
          BoltBlockArgument5.send(:anchor?).should be_true
        end
      end

      describe "with method name" do

        it "should parse without options" do
          class BoltMethodName1 < RedStorm::SimpleBolt
            on_receive :test_method
          end

          BoltMethodName1.receive_options.should == DEFAULT_RECEIVE_OPTIONS
          BoltMethodName1.send(:emit?).should be_true
          BoltMethodName1.send(:ack?).should be_false
          BoltMethodName1.send(:anchor?).should be_false
        end

        it "should parse :emit option" do
          class BoltMethodName2 < RedStorm::SimpleBolt
            on_receive :test_method, :emit => false
          end

          BoltMethodName2.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:emit => false)
          BoltMethodName2.send(:emit?).should be_false
        end

        it "should parse :ack option" do
          class BoltMethodName3 < RedStorm::SimpleBolt
            on_receive :ack => true do
            end
          end

          BoltMethodName3.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:ack => true)
          BoltMethodName3.send(:ack?).should be_true
        end

        it "should parse :anchor option" do
          class BoltMethodName4 < RedStorm::SimpleBolt
            on_receive :anchor => true do
            end
          end

          BoltMethodName4.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:anchor => true)
          BoltMethodName4.send(:anchor?).should be_true
        end

        it "should parse multiple option" do
          class BoltMethodName5 < RedStorm::SimpleBolt
            on_receive :emit => false, :ack =>true, :anchor => true do
            end
          end

          BoltMethodName5.receive_options.should == DEFAULT_RECEIVE_OPTIONS.merge(:emit =>false, :ack => true, :anchor => true)
          BoltMethodName5.send(:emit?).should be_false
          BoltMethodName5.send(:ack?).should be_true
          BoltMethodName5.send(:anchor?).should be_true
        end

      end
    end

    describe "on_init statement" do

      it "should parse block argument" do
        class BoltOnInitBlockArgument1 < RedStorm::SimpleBolt
          on_init {self.test_block_call}
        end

        bolt = BoltOnInitBlockArgument1.new
        bolt.should_receive(:test_block_call)
        bolt.prepare(nil, nil, nil)
      end

      it "should parse method name" do
        class BoltOnInitMethodName1 < RedStorm::SimpleBolt
          on_init :test_method
        end

        bolt = BoltOnInitMethodName1.new
        bolt.should_receive(:test_method)
        bolt.prepare(nil, nil, nil)
      end
    end

    describe "on_close statement" do

      it "should parse block argument" do
        class BoltOnCloseBlockArgument1 < RedStorm::SimpleBolt
          on_close {self.test_block_call}
        end

        bolt = BoltOnCloseBlockArgument1.new
        bolt.should_receive(:test_block_call)
        bolt.cleanup
      end

      it "should parse method name" do
        class BoltOnCloseMethodName1 < RedStorm::SimpleBolt
          on_close :test_method
        end

        bolt = BoltOnCloseMethodName1.new
        bolt.should_receive(:test_method)
        bolt.cleanup
      end
    end
  end

  describe "bolt" do

    describe "execute" do

      it "should auto emit on single value output" do
        class BoltNextTuple1 < RedStorm::SimpleBolt
          on_receive {|tuple| tuple}
        end
        collector = mock("Collector")

        class RedStorm::Values; end
        RedStorm::Values.should_receive(:new).with("output").and_return("values")
        collector.should_receive(:emit).with("values")

        bolt = BoltNextTuple1.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("output")
      end

      it "should auto emit on multiple value output" do
        class BoltNextTuple2 < RedStorm::SimpleBolt
          on_receive {|tuple| tuple}
        end
        collector = mock("Collector")

        class RedStorm::Values; end
        RedStorm::Values.should_receive(:new).with("output1", "output2").and_return("values")
        collector.should_receive(:emit).with("values")

        bolt = BoltNextTuple2.new
        bolt.prepare(nil, nil, collector)
        bolt.execute(["output1", "output2"])
      end

      it "should anchor on single value output" do
        class BoltNextTuple3 < RedStorm::SimpleBolt
          on_receive :anchor => true do |tuple| 
            "output"
          end
        end
        collector = mock("Collector")

        class RedStorm::Values; end
        RedStorm::Values.should_receive(:new).with("output").and_return("values")
        collector.should_receive(:emit).with("tuple", "values")

        bolt = BoltNextTuple3.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("tuple")
      end

      it "should ack on single value output" do
        class BoltNextTuple4 < RedStorm::SimpleBolt
          on_receive :anchor => true, :ack => true do |tuple| 
            "output"
          end
        end
        collector = mock("Collector")

        class RedStorm::Values; end
        RedStorm::Values.should_receive(:new).with("output").and_return("values")
        collector.should_receive(:emit).with("tuple", "values")
        collector.should_receive(:ack).with("tuple")

        bolt = BoltNextTuple4.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("tuple")
      end

      it "should not emit" do
        class BoltNextTuple5 < RedStorm::SimpleBolt
          on_receive :emit => false do |tuple| 
            tuple
          end
        end
        collector = mock("Collector")

        class RedStorm::Values; end
        RedStorm::Values.should_receive(:new).never
        collector.should_receive(:emit).never

        bolt = BoltNextTuple5.new
        bolt.prepare(nil, nil, collector)
        bolt.execute("output")
      end
    end

    describe "prepare" do
    end

    describe "cleanup" do
    end

    describe "declare_output_fields" do
    end

  end
end