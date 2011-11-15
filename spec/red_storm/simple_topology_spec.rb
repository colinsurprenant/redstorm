require 'spec_helper'
require 'red_storm/simple_topology'

describe RedStorm::SimpleTopology do

  it "should set default topology name" do
    class DefaultTopologyName < RedStorm::SimpleTopology; end
    DefaultTopologyName.topology_name.should == "default_topology_name"
  end


  describe "interface" do
    it "should implement topology proxy" do
      topology = RedStorm::SimpleTopology.new
      topology.should respond_to :start
    end

    it "should implement dsl statement" do
      RedStorm::SimpleTopology.should respond_to :spout
      RedStorm::SimpleTopology.should respond_to :bolt
      RedStorm::SimpleTopology.should respond_to :configure
      RedStorm::SimpleTopology.should respond_to :on_submit
    end
  end

  describe "dsl" do

    describe "spout statement" do

      class SpoutClass1; end
      class SpoutClass2; end

      it "should parse single spout without options" do
        RedStorm::SimpleTopology::SpoutDefinition.should_receive(:new).with(SpoutClass1, "spout_class1", 1).and_return("spout_definition")
        class TopologySpout1 < RedStorm::SimpleTopology
          spout SpoutClass1
        end
        TopologySpout1.spouts.should == ["spout_definition"]
      end

      it "should parse multiple spouts with options" do
        RedStorm::SimpleTopology::SpoutDefinition.should_receive(:new).with(SpoutClass1, "id1", 2).and_return("spout_definition1")
        RedStorm::SimpleTopology::SpoutDefinition.should_receive(:new).with(SpoutClass2, "id2", 3).and_return("spout_definition2")
        class TopologySpout2 < RedStorm::SimpleTopology
          spout SpoutClass1, :id => "id1", :parallelism => 2
          spout SpoutClass2, :id => "id2", :parallelism => 3
        end
        TopologySpout2.spouts.should == ["spout_definition1", "spout_definition2"]
      end

    end

    describe "bolt statement" do

      class BoltClass1; end
      class BoltClass2; end

      it "should parse single bolt without options" do
        bolt_definition = mock("BoltDefinition")
        RedStorm::SimpleTopology::BoltDefinition.should_receive(:new).with(BoltClass1, "bolt_class1", 1).and_return(bolt_definition)
        bolt_definition.should_receive(:source).with(1, {:fields => ["f1"]})
        class TopologyBolt1 < RedStorm::SimpleTopology
          bolt BoltClass1 do
            source 1, :fields => ["f1"]
          end
        end
        TopologyBolt1.bolts.should == [bolt_definition]
      end

      it "should parse single bolt with options" do
        bolt_definition = mock("BoltDefinition")
        RedStorm::SimpleTopology::BoltDefinition.should_receive(:new).with(BoltClass1, "id", 2).and_return(bolt_definition)
        bolt_definition.should_receive(:source).with(1, :shuffle)
        class TopologyBolt2 < RedStorm::SimpleTopology
          bolt BoltClass1, :id => "id", :parallelism => 2 do
            source 1, :shuffle
          end
        end
        TopologyBolt2.bolts.should == [bolt_definition]
      end

      it "should parse multiple bolt with options" do
        bolt_definition1 = mock("BoltDefinition")
        bolt_definition2 = mock("BoltDefinition")
        RedStorm::SimpleTopology::BoltDefinition.should_receive(:new).with(BoltClass1, "id1", 2).and_return(bolt_definition1)
        RedStorm::SimpleTopology::BoltDefinition.should_receive(:new).with(BoltClass2, "id2", 3).and_return(bolt_definition2)
        bolt_definition1.should_receive(:source).with(1, :shuffle)
        bolt_definition2.should_receive(:source).with(2, {:fields => ["f1"]})
        class TopologyBolt3 < RedStorm::SimpleTopology
          bolt BoltClass1, :id => "id1", :parallelism => 2 do
            source 1, :shuffle
          end
          bolt BoltClass2, :id => "id2", :parallelism => 3 do
            source 2, :fields => ["f1"]
          end
        end
        TopologyBolt3.bolts.should == [bolt_definition1, bolt_definition2]
      end

    end

    describe "configure statement" do

      it "should parse name options only" do
        class TopologyConfigure1 < RedStorm::SimpleTopology
          configure "name"
        end
        TopologyConfigure1.topology_name.should == "name"
      end

      it "should parse configuration block only" do
        class TopologyConfigure2 < RedStorm::SimpleTopology
          configure {trigger}
        end
        topology = TopologyConfigure2.new
        topology.should_receive(:trigger)
        topology.instance_exec(&TopologyConfigure2.configure_block)
      end

      it "should parse name and configuration block" do
        class TopologyConfigure3 < RedStorm::SimpleTopology
          configure "name" do
            trigger
          end
        end
        TopologyConfigure3.topology_name.should == "name"
        topology = TopologyConfigure3.new
        topology.should_receive(:trigger)
        topology.instance_exec(&TopologyConfigure3.configure_block)
      end
    end

    define "on_submit statement" do

      it "should parse block param only" do
        class TopologyOnsubmit1 < RedStorm::SimpleTopology
          on_submit {|env| trigger(env)}
        end
        topology = TopologyOnsubmit1.new
        topology.should_receive(:trigger).with("env")
        topology.instance_exec("env", &TopologyOnsubmit1.submit_block)
      end

      it "should method name param only" do
        class TopologyOnsubmit1 < RedStorm::SimpleTopology
          on_submit :my_method
        end
        topology = TopologyOnsubmit1.new
        topology.should_receive(:my_method).with("env")
        topology.instance_exec("env", &TopologyOnsubmit1.submit_block)
      end
    end
  end

  describe "topology proxy" do

    class RedStorm::TopologyBuilder; end
    class RedStorm::LocalCluster; end
    class RedStorm::StormSubmitter; end
    class RedStorm::JRubySpout; end
    class RedStorm::JRubyBolt; end
    class RedStorm::Config; end

    it "should start in :local env" do
      class TopologyStart1 < RedStorm::SimpleTopology; end

      builder = mock(RedStorm::TopologyBuilder)
      RedStorm::TopologyBuilder.should_receive(:new).and_return(builder)
      builder.should_receive(:createTopology).and_return("topology")
      configurator = mock(RedStorm::SimpleTopology::Configurator)
      RedStorm::SimpleTopology::Configurator.should_receive(:new).and_return(configurator)
      configurator.should_receive(:config).and_return("config")
      cluster = mock(RedStorm::LocalCluster)
      RedStorm::LocalCluster.should_receive(:new).and_return(cluster)
      cluster.should_receive(:submitTopology).with("topology_start1", "config", "topology")
      TopologyStart1.new.start("base_path", :local)
    end  

    it "should start in :cluster env" do
      class TopologyStart2 < RedStorm::SimpleTopology; end
      builder = mock(RedStorm::TopologyBuilder)
      RedStorm::TopologyBuilder.should_receive(:new).and_return(builder)
      builder.should_receive(:createTopology).and_return("topology")
      configurator = mock(RedStorm::SimpleTopology::Configurator)
      RedStorm::SimpleTopology::Configurator.should_receive(:new).and_return(configurator)
      configurator.should_receive(:config).and_return("config")
      RedStorm::StormSubmitter.should_receive("submitTopology").with("topology_start2", "config", "topology")
      TopologyStart2.new.start("base_path", :cluster)
    end 

    it "should raise for invalid env" do
      class TopologyStart3 < RedStorm::SimpleTopology; end
      lambda {TopologyStart3.new.start("base_path", :toto)}.should raise_error
    end

    it "should build spouts" do
      class TopologyStart4 < RedStorm::SimpleTopology
        spout SpoutClass1
        spout SpoutClass2
      end
      
      builder = mock(RedStorm::TopologyBuilder)
      configurator = mock(RedStorm::SimpleTopology::Configurator)
      jruby_spout1 = mock(RedStorm::JRubySpout)
      jruby_spout2 = mock(RedStorm::JRubySpout)

      RedStorm::TopologyBuilder.should_receive(:new).and_return(builder)
      RedStorm::SimpleTopology::Configurator.should_receive(:new).and_return(configurator)
      RedStorm::JRubySpout.should_receive(:new).with("base_path", "SpoutClass1").and_return(jruby_spout1)
      RedStorm::JRubySpout.should_receive(:new).with("base_path", "SpoutClass2").and_return(jruby_spout2)

      builder.should_receive("setSpout").with(1, jruby_spout1, 1)
      builder.should_receive("setSpout").with(2, jruby_spout2, 1)
      configurator.should_receive(:config).and_return("config")
      builder.should_receive(:createTopology).and_return("topology")
      RedStorm::StormSubmitter.should_receive("submitTopology").with("topology_start4", "config", "topology")
      TopologyStart4.new.start("base_path", :cluster)
    end

    it "should build bolts" do
      bolt_definition1 = mock("BoltDefinition")
      bolt_definition2 = mock("BoltDefinition")
      RedStorm::SimpleTopology::BoltDefinition.should_receive(:new).with(BoltClass1, "id1", 2).and_return(bolt_definition1)
      RedStorm::SimpleTopology::BoltDefinition.should_receive(:new).with(BoltClass2, "id2", 3).and_return(bolt_definition2)
      bolt_definition1.should_receive(:source).with(1, :shuffle)
      bolt_definition2.should_receive(:source).with(2, {:fields => ["f1"]})

      class TopologyStart5 < RedStorm::SimpleTopology
        bolt BoltClass1, :id => "id1", :parallelism => 2 do
          source 1, :shuffle
        end
        bolt BoltClass2, :id => "id2", :parallelism => 3 do
          source 2, :fields => ["f1"]
        end
      end
      
      builder = mock(RedStorm::TopologyBuilder)
      configurator = mock(RedStorm::SimpleTopology::Configurator)
      jruby_bolt1 = mock(RedStorm::JRubyBolt)
      jruby_bolt2 = mock(RedStorm::JRubyBolt)

      RedStorm::TopologyBuilder.should_receive(:new).and_return(builder)
      RedStorm::SimpleTopology::Configurator.should_receive(:new).and_return(configurator)
      RedStorm::JRubyBolt.should_receive(:new).with("base_path", "BoltClass1").and_return(jruby_bolt1)
      RedStorm::JRubyBolt.should_receive(:new).with("base_path", "BoltClass2").and_return(jruby_bolt2)

      builder.should_receive("setBolt").with("id1", jruby_bolt1, 2).and_return("storm_bolt1")
      builder.should_receive("setBolt").with("id2", jruby_bolt2, 3).and_return("storm_bolt2") 

      bolt_definition1.should_receive(:define_grouping).with("storm_bolt1")
      bolt_definition2.should_receive(:define_grouping).with("storm_bolt2")
      bolt_definition1.should_receive(:clazz).and_return(BoltClass1)
      bolt_definition2.should_receive(:clazz).and_return(BoltClass2)
      bolt_definition1.should_receive(:parallelism).and_return(2)
      bolt_definition2.should_receive(:parallelism).and_return(3)
      bolt_definition1.should_receive(:id).any_number_of_times.and_return("id1")
      bolt_definition2.should_receive(:id).any_number_of_times.and_return("id2")
      bolt_definition1.should_receive(:id=).with(1)
      bolt_definition2.should_receive(:id=).with(2)

      configurator.should_receive(:config).and_return("config")
      builder.should_receive(:createTopology).and_return("topology")
      RedStorm::StormSubmitter.should_receive("submitTopology").with("topology_start5", "config", "topology")

      TopologyStart5.new.start("base_path", :cluster)
    end

    it "should configure" do
      class TopologyStart6 < RedStorm::SimpleTopology
        configure do
          debug true
          max_task_parallelism 3
        end
      end

      config = mock(RedStorm::Config)
      RedStorm::Config.should_receive(:new).and_return(config)
      config.should_receive(:setDebug).with(true)
      config.should_receive(:setMaxTaskParallelism).with(3)

      builder = mock(RedStorm::TopologyBuilder)
      RedStorm::TopologyBuilder.should_receive(:new).and_return(builder)
      builder.should_receive(:createTopology).and_return("topology")
      RedStorm::StormSubmitter.should_receive("submitTopology").with("topology_start6", config, "topology")

      TopologyStart6.new.start("base_path", :cluster)
    end

    it "should provide local cluster reference" do
      class TopologyStart7 < RedStorm::SimpleTopology; end

      builder = mock(RedStorm::TopologyBuilder)
      RedStorm::TopologyBuilder.should_receive(:new).and_return(builder)
      builder.should_receive(:createTopology).and_return("topology")
      configurator = mock(RedStorm::SimpleTopology::Configurator)
      RedStorm::SimpleTopology::Configurator.should_receive(:new).and_return(configurator)
      configurator.should_receive(:config).and_return("config")

      cluster = mock(RedStorm::LocalCluster)
      RedStorm::LocalCluster.should_receive(:new).and_return(cluster)
      cluster.should_receive(:submitTopology).with("topology_start7", "config", "topology").and_return("cluster")

      topology = TopologyStart7.new
      topology.start("base_path", :local)

      topology.cluster.should == cluster
    end

    it "should keep numeric ids" do
      class TopologyNumericIds1 < RedStorm::SimpleTopology
        spout SpoutClass1, :id => 1

        bolt BoltClass1, :id => 2 do
          source 1, :shuffle
        end
      end

      TopologyNumericIds1.spouts.first.id.should == 1
      TopologyNumericIds1.bolts.first.id.should == 2
      TopologyNumericIds1.bolts.first.sources.first.should == [1, {:shuffle => nil}]

      TopologyNumericIds1.resolve_ids!(TopologyNumericIds1.spouts + TopologyNumericIds1.bolts)

      TopologyNumericIds1.spouts.first.id.should == 1
      TopologyNumericIds1.bolts.first.id.should == 2
      TopologyNumericIds1.bolts.first.sources.first.should == [1, {:shuffle => nil}]
    end

    it "should resolve explicit symbolic ids" do
      class TopologySymbolicIds1 < RedStorm::SimpleTopology
        spout SpoutClass1, :id => "id1"

        bolt BoltClass1, :id => "id2" do
          source "id1", :shuffle
        end
      end
      
      TopologySymbolicIds1.spouts.first.id.should == "id1"
      TopologySymbolicIds1.bolts.first.id.should == "id2"
      TopologySymbolicIds1.bolts.first.sources.first.should == ["id1", {:shuffle => nil}]

      TopologySymbolicIds1.resolve_ids!(TopologySymbolicIds1.spouts + TopologySymbolicIds1.bolts)

      TopologySymbolicIds1.spouts.first.id.should == 1
      TopologySymbolicIds1.bolts.first.id.should == 2
      TopologySymbolicIds1.bolts.first.sources.first.should == [1, {:shuffle => nil}]
    end

    it "should resolve implicit symbolic ids" do
      class TopologySymbolicIds2 < RedStorm::SimpleTopology
        spout SpoutClass1

        bolt BoltClass1 do
          source "spout_class1", :shuffle
        end
      end
      
      TopologySymbolicIds2.spouts.first.id.should == "spout_class1"
      TopologySymbolicIds2.bolts.first.id.should == "bolt_class1"
      TopologySymbolicIds2.bolts.first.sources.first.should == ["spout_class1", {:shuffle => nil}]

      TopologySymbolicIds2.resolve_ids!(TopologySymbolicIds2.spouts + TopologySymbolicIds2.bolts)

      TopologySymbolicIds2.spouts.first.id.should == 1
      TopologySymbolicIds2.bolts.first.id.should == 2
      TopologySymbolicIds2.bolts.first.sources.first.should == [1, {:shuffle => nil}]
    end

    it "should raise on unresolvable" do
      class TopologySymbolicIds3 < RedStorm::SimpleTopology
        spout SpoutClass1

        bolt BoltClass1 do
          source "dummy", :shuffle
        end
      end
      
      TopologySymbolicIds3.spouts.first.id.should == "spout_class1"
      TopologySymbolicIds3.bolts.first.id.should == "bolt_class1"
      TopologySymbolicIds3.bolts.first.sources.first.should == ["dummy", {:shuffle => nil}]

      lambda {TopologySymbolicIds3.resolve_ids!(TopologySymbolicIds3.spouts + TopologySymbolicIds3.bolts)}.should raise_error RuntimeError, "cannot resolve BoltClass1 source id=\"dummy\""
    end

  end
end