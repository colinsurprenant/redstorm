require 'spec_helper'
require 'red_storm/simple_spout'

describe RedStorm::SimpleSpout do

  describe "interface" do
    it "should implement spout proxy" do
      spout = RedStorm::SimpleSpout.new
      spout.should respond_to :next_tuple
      spout.should respond_to :open
      spout.should respond_to :close
      spout.should respond_to :declare_output_fields
      spout.should respond_to :is_distributed
      spout.should respond_to :ack
      spout.should respond_to :fail
    end

    it "should implement dsl statement" do
      RedStorm::SimpleSpout.should respond_to :set
      RedStorm::SimpleSpout.should respond_to :output_fields
      RedStorm::SimpleSpout.should respond_to :on_init
      RedStorm::SimpleSpout.should respond_to :on_close
      RedStorm::SimpleSpout.should respond_to :on_send
      RedStorm::SimpleSpout.should respond_to :on_ack
      RedStorm::SimpleSpout.should respond_to :on_fail      
    end
  end

  describe "dsl" do

    describe "set statement" do
      DEFAULT_SPOUT_OPTIONS = {:is_distributed => false}

      it "should have default options" do
        RedStorm::SimpleSpout.send(:is_distributed?).should be_false
      end

      it "should parse options" do
        class IsDistributedClass < RedStorm::SimpleSpout
          set :is_distributed => true
        end
        IsDistributedClass.send(:spout_options).should == DEFAULT_SPOUT_OPTIONS.merge(:is_distributed => true)
        IsDistributedClass.send(:is_distributed?).should be_true
      end
    end

    describe "output_field statement" do
      it "should parse single argument" do
        class Test1 < RedStorm::SimpleSpout
          output_fields :f1
        end
        test1 = Test1.new
        Test1.send(:fields).should == ["f1"]
      end

      it "should parse multiple arguments" do
        class Test2 < RedStorm::SimpleSpout
          output_fields :f1, :f2
        end
        Test2.send(:fields).should == ["f1", "f2"]
      end

      it "should parse string and symbol arguments" do
        class Test3 < RedStorm::SimpleSpout
          output_fields :f1, "f2"
        end
        Test3.send(:fields).should == ["f1", "f2"]
      end

      it "should not share state over mutiple classes" do
        class Test4 < RedStorm::SimpleSpout
          output_fields :f1
        end
        class Test5 < RedStorm::SimpleSpout
          output_fields :f2
        end
        RedStorm::SimpleSpout.send(:fields).should == []
        Test4.send(:fields).should == ["f1"]
        Test5.send(:fields).should == ["f2"]
      end
    end

    describe "on_send statement" do
      DEFAULT_SEND_OPTIONS = {:emit => true}

      it "should emit by defaut" do
        RedStorm::SimpleSpout.send(:emit?).should be_true
      end

      describe "with block argument" do

        it "should parse without options" do
          class BlockArgument1 < RedStorm::SimpleSpout
            on_send {self.test_method}
          end

          BlockArgument1.send_options.should == DEFAULT_SEND_OPTIONS

          spout = BlockArgument1.new
          spout.should_receive(:test_method)
          BlockArgument1.should_receive(:emit?).and_return(false)
          spout.next_tuple
        end

        it "should parse :emit option" do
          class BlockArgument2 < RedStorm::SimpleSpout
            on_send :emit => false do
              self.test_method
            end
          end

          BlockArgument2.send_options.should == DEFAULT_SEND_OPTIONS.merge(:emit => false)
          BlockArgument2.send(:emit?).should be_false

          spout = BlockArgument2.new
          spout.should_receive(:test_method)
          spout.next_tuple
        end
      end

      describe "with method name" do

        it "should parse without options" do
          class MethodName1 < RedStorm::SimpleSpout
            on_send :test_method
          end

          MethodName1.send_options.should == DEFAULT_SEND_OPTIONS

          spout = MethodName1.new
          spout.should_receive(:test_method)
          MethodName1.should_receive(:emit?).and_return(false)
          spout.next_tuple
        end

        it "should parse :emit option" do
          class MethodName2 < RedStorm::SimpleSpout
            on_send :test_method, :emit => false
          end

          MethodName2.send_options.should == DEFAULT_SEND_OPTIONS.merge(:emit => false)
          MethodName2.send(:emit?).should be_false

          spout = MethodName2.new
          spout.should_receive(:test_method)
          spout.next_tuple
        end
      end
    end

    describe "on_init statement" do

      it "should parse block argument" do
        class OnInitBlockArgument1 < RedStorm::SimpleSpout
          on_init {self.test_block_call}
        end

        spout = OnInitBlockArgument1.new
        spout.should_receive(:test_block_call)
        spout.open(nil, nil, nil)
      end

      it "should parse method name" do
        class OnInitMethodName1 < RedStorm::SimpleSpout
          on_init :test_method
        end

        spout = OnInitMethodName1.new
        spout.should_receive(:test_method)
        spout.open(nil, nil, nil)
      end
    end

    describe "on_close statement" do

      it "should parse block argument" do
        class OnCloseBlockArgument1 < RedStorm::SimpleSpout
          on_close {self.test_block_call}
        end

        spout = OnCloseBlockArgument1.new
        spout.should_receive(:test_block_call)
        spout.close
      end

      it "should parse method name" do
        class OnCloseMethodName1 < RedStorm::SimpleSpout
          on_close :test_method
        end

        spout = OnCloseMethodName1.new
        spout.should_receive(:test_method)
        spout.close
      end
    end

    describe "on_ack statement" do

      it "should parse block argument" do
        class OnAckBlockArgument1 < RedStorm::SimpleSpout
          on_ack {|msg_id| self.test_block_call(msg_id)}
        end

        spout = OnAckBlockArgument1.new
        spout.should_receive(:test_block_call).with("test")
        spout.ack("test")
      end

      it "should parse method name" do
        class OnAckMethodName1 < RedStorm::SimpleSpout
          on_ack :test_method
        end

        spout = OnAckMethodName1.new
        spout.should_receive(:test_method).with("test")
        spout.ack("test")
      end
    end

    describe "on_fail statement" do

      it "should parse block argument" do
        class OnFailBlockArgument1 < RedStorm::SimpleSpout
          on_fail {|msg_id| self.test_block_call(msg_id)}
        end

        spout = OnFailBlockArgument1.new
        spout.should_receive(:test_block_call).with("test")
        spout.fail("test")
      end

      it "should parse method name" do
        class OnFailMethodName1 < RedStorm::SimpleSpout
          on_fail :test_method
        end

        spout = OnFailMethodName1.new
        spout.should_receive(:test_method).with("test")
        spout.fail("test")
      end
    end

  end

  describe "spout" do

    describe "next_tuple" do

      it "should auto emit on single value output" do
        class SpoutNextTuple1 < RedStorm::SimpleSpout
          on_send {"output"}
        end
        collector = mock("Collector")

        class RedStorm::Values; end
        RedStorm::Values.should_receive(:new).with("output").and_return("values")
        collector.should_receive(:emit).with("values")

        spout = SpoutNextTuple1.new
        spout.open(nil, nil, collector)
        spout.next_tuple
      end

      it "should auto emit on multiple values output" do
        class SpoutNextTuple2 < RedStorm::SimpleSpout
          on_send {["output1", "output2"]}
        end
        collector = mock("Collector")

        class RedStorm::Values; end
        RedStorm::Values.should_receive(:new).with("output1", "output2").and_return("values")
        collector.should_receive(:emit).with("values")

        spout = SpoutNextTuple2.new
        spout.open(nil, nil, collector)
        spout.next_tuple
      end

      it "should sleep on nil output" do
        class SpoutNextTuple2 < RedStorm::SimpleSpout
          on_send {nil}
        end
        collector = mock("Collector")

        class RedStorm::Values; end
        RedStorm::Values.should_receive(:new).never
        collector.should_receive(:emit).never

        spout = SpoutNextTuple2.new
        spout.should_receive(:sleep)
        spout.open(nil, nil, collector)
        spout.next_tuple
      end

      it "should respect :emit => false" do
        class SpoutNextTuple3 < RedStorm::SimpleSpout
          on_send :emit => false do 
            "output"
          end
        end
        collector = mock("Collector")

        class RedStorm::Values; end
        RedStorm::Values.should_receive(:new).never
        collector.should_receive(:emit).never

        spout = SpoutNextTuple3.new
        spout.should_receive(:sleep).never
        spout.open(nil, nil, collector)
        spout.next_tuple
      end
    end

    describe "open" do
    end

    describe "close" do
    end
 
    describe "declare_output_fields" do
    end

    describe "is_distributed" do
    end

    describe "ack" do
    end

    describe "fail" do
    end
    
  end
end