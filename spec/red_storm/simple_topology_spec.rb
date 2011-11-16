require 'spec_helper'
require 'red_storm/simple_topology'

describe RedStorm::SimpleTopology do

  before(:each) do
    Object.send(:remove_const, "Topology1") if Object.const_defined?("Topology1")
    Object.send(:remove_const, "Topology2") if Object.const_defined?("Topology2")
    Object.send(:remove_const, "Topology3") if Object.const_defined?("Topology3")
  end

  it "should set default topology name" do
    class Topology1 < RedStorm::SimpleTopology; end
    Topology1.topology_name.should == "topology1"
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
        spout =  RedStorm::SimpleTopology::SpoutDefinition.new(SpoutClass1, "spout_class1", 1)
        RedStorm::SimpleTopology::SpoutDefinition.should_receive(:new).with(SpoutClass1, "spout_class1", 1).and_return(spout)
        class Topology1 < RedStorm::SimpleTopology
          spout SpoutClass1
        end
        Topology1.spouts.should == [spout]
      end

      it "should parse multiple spouts with options" do
        spout1 =  RedStorm::SimpleTopology::SpoutDefinition.new(SpoutClass1, "id1", 2)
        spout2 =  RedStorm::SimpleTopology::SpoutDefinition.new(SpoutClass2, "id2", 3)
        RedStorm::SimpleTopology::SpoutDefinition.should_receive(:new).with(SpoutClass1, "id1", 2).and_return(spout1)
        RedStorm::SimpleTopology::SpoutDefinition.should_receive(:new).with(SpoutClass2, "id2", 3).and_return(spout2)
        class Topology1 < RedStorm::SimpleTopology
          spout SpoutClass1, :id => "id1", :parallelism => 2
          spout SpoutClass2, :id => "id2", :parallelism => 3
        end
        Topology1.spouts.should == [spout1, spout2]
      end

    end

    describe "bolt statement" do

      class BoltClass1; end
      class BoltClass2; end

      it "should parse single bolt without options" do
        bolt_definition = RedStorm::SimpleTopology::BoltDefinition.new(BoltClass1, "bolt_class1", 1)
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
        bolt_definition = RedStorm::SimpleTopology::BoltDefinition.new(BoltClass1, "id", 2)
        RedStorm::SimpleTopology::BoltDefinition.should_receive(:new).with(BoltClass1, "id", 2).and_return(bolt_definition)
        bolt_definition.should_receive(:source).with(1, :shuffle)
        class Topology1 < RedStorm::SimpleTopology
          bolt BoltClass1, :id => "id", :parallelism => 2 do
            source 1, :shuffle
          end
        end
        Topology1.bolts.should == [bolt_definition]
      end

      it "should parse multiple bolt with options" do
        bolt_definition1 = RedStorm::SimpleTopology::BoltDefinition.new(BoltClass1, "id1", 2)
        bolt_definition2 = RedStorm::SimpleTopology::BoltDefinition.new(BoltClass2, "id2", 3)
        RedStorm::SimpleTopology::BoltDefinition.should_receive(:new).with(BoltClass1, "id1", 2).and_return(bolt_definition1)
        RedStorm::SimpleTopology::BoltDefinition.should_receive(:new).with(BoltClass2, "id2", 3).and_return(bolt_definition2)
        bolt_definition1.should_receive(:source).with(1, :shuffle)
        bolt_definition2.should_receive(:source).with(2, {:fields => ["f1"]})
        class Topology1 < RedStorm::SimpleTopology
          bolt BoltClass1, :id => "id1", :parallelism => 2 do
            source 1, :shuffle
          end
          bolt BoltClass2, :id => "id2", :parallelism => 3 do
            source 2, :fields => ["f1"]
          end
        end
        Topology1.bolts.should == [bolt_definition1, bolt_definition2]
      end

    end

    describe "configure statement" do

      it "should parse name options only" do
        class Topology1 < RedStorm::SimpleTopology
          configure "name"
        end
        Topology1.topology_name.should == "name"
      end

      it "should parse configuration block only" do
        class Topology1 < RedStorm::SimpleTopology
          configure {trigger}
        end
        topology = Topology1.new
        topology.should_receive(:trigger)
        topology.instance_exec(&Topology1.configure_block)
      end

      it "should parse name and configuration block" do
        class Topology1 < RedStorm::SimpleTopology
          configure "name" do
            trigger
          end
        end
        Topology1.topology_name.should == "name"
        topology = Topology1.new
        topology.should_receive(:trigger)
        topology.instance_exec(&Topology1.configure_block)
      end
    end

    define "on_submit statement" do

      it "should parse block param only" do
        class Topology1 < RedStorm::SimpleTopology
          on_submit {|env| trigger(env)}
        end
        topology = Topology1.new
        topology.should_receive(:trigger).with("env")
        topology.instance_exec("env", &Topology1.submit_block)
      end

      it "should method name param only" do
        class Topology1 < RedStorm::SimpleTopology
          on_submit :my_method
        end
        topology = Topology1.new
        topology.should_receive(:my_method).with("env")
        topology.instance_exec("env", &Topology1.submit_block)
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
    class RedStorm::Fields; end

    it "should start in :local env" do
      class Topology1 < RedStorm::SimpleTopology; end

      builder = mock(RedStorm::TopologyBuilder)
      RedStorm::TopologyBuilder.should_receive(:new).and_return(builder)
      builder.should_receive(:createTopology).and_return("topology")
      configurator = mock(RedStorm::SimpleTopology::Configurator)
      RedStorm::SimpleTopology::Configurator.should_receive(:new).and_return(configurator)
      configurator.should_receive(:config).and_return("config")
      cluster = mock(RedStorm::LocalCluster)
      RedStorm::LocalCluster.should_receive(:new).and_return(cluster)
      cluster.should_receive(:submitTopology).with("topology1", "config", "topology")
      Topology1.new.start("base_path", :local)
    end  

    it "should start in :cluster env" do
      class Topology1 < RedStorm::SimpleTopology; end
      builder = mock(RedStorm::TopologyBuilder)
      RedStorm::TopologyBuilder.should_receive(:new).and_return(builder)
      builder.should_receive(:createTopology).and_return("topology")
      configurator = mock(RedStorm::SimpleTopology::Configurator)
      RedStorm::SimpleTopology::Configurator.should_receive(:new).and_return(configurator)
      configurator.should_receive(:config).and_return("config")
      RedStorm::StormSubmitter.should_receive("submitTopology").with("topology1", "config", "topology")
      Topology1.new.start("base_path", :cluster)
    end 

    it "should raise for invalid env" do
      class Topology1 < RedStorm::SimpleTopology; end
      lambda {Topology1.new.start("base_path", :toto)}.should raise_error
    end

    it "should build spouts" do
      class Topology1 < RedStorm::SimpleTopology
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
      RedStorm::StormSubmitter.should_receive("submitTopology").with("topology1", "config", "topology")
      Topology1.new.start("base_path", :cluster)
    end

    it "should build bolts" do
      bolt_definition1 = RedStorm::SimpleTopology::BoltDefinition.new(BoltClass1, "id1", 2)
      bolt_definition2 = RedStorm::SimpleTopology::BoltDefinition.new(BoltClass2, "id2", 3)
      RedStorm::SimpleTopology::BoltDefinition.should_receive(:new).with(BoltClass1, "id1", 2).and_return(bolt_definition1)
      RedStorm::SimpleTopology::BoltDefinition.should_receive(:new).with(BoltClass2, "id2", 3).and_return(bolt_definition2)
      bolt_definition1.should_receive(:source).with(1, :shuffle)
      bolt_definition2.should_receive(:source).with(2, {:fields => ["f1"]})

      class Topology1 < RedStorm::SimpleTopology
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
      RedStorm::StormSubmitter.should_receive("submitTopology").with("topology1", "config", "topology")

      Topology1.new.start("base_path", :cluster)
    end


    describe "grouping" do

      before(:each) do
        builder = mock(RedStorm::TopologyBuilder)
        configurator = mock(RedStorm::SimpleTopology::Configurator)
        jruby_bolt = mock(RedStorm::JRubyBolt)
        @declarer = mock("InputDeclarer")
        RedStorm::TopologyBuilder.should_receive(:new).and_return(builder)
        RedStorm::SimpleTopology::Configurator.should_receive(:new).and_return(configurator)
        RedStorm::JRubyBolt.should_receive(:new).with("base_path", "BoltClass1").and_return(jruby_bolt)
        builder.should_receive("setBolt").with(1, jruby_bolt, 1).and_return(@declarer)
        configurator.should_receive(:config).and_return("config")
        builder.should_receive(:createTopology).and_return("topology")
        RedStorm::StormSubmitter.should_receive("submitTopology").with("topology1", "config", "topology")
      end

      it "should support fields" do
        class Topology1 < RedStorm::SimpleTopology
          bolt BoltClass1 do
            source 1, :fields => "f1"
          end
        end

        RedStorm::Fields.should_receive(:new).with("f1").and_return("fields")
        @declarer.should_receive("fieldsGrouping").with(1, "fields")
        Topology1.new.start("base_path", :cluster)
      end

      it "should support shuffle" do
        class Topology1 < RedStorm::SimpleTopology
          bolt BoltClass1 do
            source 1, :shuffle
          end
        end
        
        @declarer.should_receive("shuffleGrouping").with(1)
        Topology1.new.start("base_path", :cluster)
      end

      it "should support none" do
        class Topology1 < RedStorm::SimpleTopology
          bolt BoltClass1 do
            source 1, :none
          end
        end
        
        @declarer.should_receive("noneGrouping").with(1)
        Topology1.new.start("base_path", :cluster)
      end

      it "should support global" do
        class Topology1 < RedStorm::SimpleTopology
          bolt BoltClass1 do
            source 1, :global
          end
        end
        
        @declarer.should_receive("globalGrouping").with(1)
        Topology1.new.start("base_path", :cluster)
      end

      it "should support all" do
        class Topology1 < RedStorm::SimpleTopology
          bolt BoltClass1 do
            source 1, :all
          end
        end
        
        @declarer.should_receive("allGrouping").with(1)
        Topology1.new.start("base_path", :cluster)
      end

      it "should support direct" do
        class Topology1 < RedStorm::SimpleTopology
          bolt BoltClass1 do
            source 1, :direct
          end
        end
        
        @declarer.should_receive("directGrouping").with(1)
        Topology1.new.start("base_path", :cluster)
      end
    end

    it "should configure" do
      class Topology1 < RedStorm::SimpleTopology
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
      RedStorm::StormSubmitter.should_receive("submitTopology").with("topology1", config, "topology")

      Topology1.new.start("base_path", :cluster)
    end

    it "should provide local cluster reference" do
      class Topology1 < RedStorm::SimpleTopology; end

      builder = mock(RedStorm::TopologyBuilder)
      RedStorm::TopologyBuilder.should_receive(:new).and_return(builder)
      builder.should_receive(:createTopology).and_return("topology")
      configurator = mock(RedStorm::SimpleTopology::Configurator)
      RedStorm::SimpleTopology::Configurator.should_receive(:new).and_return(configurator)
      configurator.should_receive(:config).and_return("config")

      cluster = mock(RedStorm::LocalCluster)
      RedStorm::LocalCluster.should_receive(:new).and_return(cluster)
      cluster.should_receive(:submitTopology).with("topology1", "config", "topology").and_return("cluster")

      topology = Topology1.new
      topology.start("base_path", :local)

      topology.cluster.should == cluster
    end

    it "should keep numeric ids" do
      class Topology1 < RedStorm::SimpleTopology
        spout SpoutClass1, :id => 1

        bolt BoltClass1, :id => 2 do
          source 1, :shuffle
        end
      end

      Topology1.spouts.first.id.should == 1
      Topology1.bolts.first.id.should == 2
      Topology1.bolts.first.sources.first.should == [1, {:shuffle => nil}]

      Topology1.resolve_ids!(Topology1.spouts + Topology1.bolts)

      Topology1.spouts.first.id.should == 1
      Topology1.bolts.first.id.should == 2
      Topology1.bolts.first.sources.first.should == [1, {:shuffle => nil}]
    end

    it "should resolve explicit symbolic ids" do
      class Topology1 < RedStorm::SimpleTopology
        spout SpoutClass1, :id => "id1"

        bolt BoltClass1, :id => "id2" do
          source "id1", :shuffle
        end
      end
      
      Topology1.spouts.first.id.should == "id1"
      Topology1.bolts.first.id.should == "id2"
      Topology1.bolts.first.sources.first.should == ["id1", {:shuffle => nil}]

      Topology1.resolve_ids!(Topology1.spouts + Topology1.bolts)

      Topology1.spouts.first.id.should == 1
      Topology1.bolts.first.id.should == 2
      Topology1.bolts.first.sources.first.should == [1, {:shuffle => nil}]
    end

    it "should resolve implicit string ids" do
      class Topology1 < RedStorm::SimpleTopology
        spout SpoutClass1

        bolt BoltClass1 do
          source "spout_class1", :shuffle
        end
      end
      
      Topology1.spouts.first.id.should == "spout_class1"
      Topology1.bolts.first.id.should == "bolt_class1"
      Topology1.bolts.first.sources.first.should == ["spout_class1", {:shuffle => nil}]

      Topology1.resolve_ids!(Topology1.spouts + Topology1.bolts)

      Topology1.spouts.first.id.should == 1
      Topology1.bolts.first.id.should == 2
      Topology1.bolts.first.sources.first.should == [1, {:shuffle => nil}]
    end

    it "should resolve implicit symbol ids" do
      class Topology1 < RedStorm::SimpleTopology
        spout SpoutClass1

        bolt BoltClass1 do
          source :spout_class1, :shuffle
        end
      end
      
      Topology1.spouts.first.id.should == "spout_class1"
      Topology1.bolts.first.id.should == "bolt_class1"
      Topology1.bolts.first.sources.first.should == [:spout_class1, {:shuffle => nil}]

      Topology1.resolve_ids!(Topology1.spouts + Topology1.bolts)

      Topology1.spouts.first.id.should == 1
      Topology1.bolts.first.id.should == 2
      Topology1.bolts.first.sources.first.should == [1, {:shuffle => nil}]
    end

    it "should resolve implicit class ids" do
      class Topology1 < RedStorm::SimpleTopology
        spout SpoutClass1

        bolt BoltClass1 do
          source SpoutClass1, :shuffle
        end
      end
      
      Topology1.spouts.first.id.should == "spout_class1"
      Topology1.bolts.first.id.should == "bolt_class1"
      Topology1.bolts.first.sources.first.should == ["spout_class1", {:shuffle => nil}]

      Topology1.resolve_ids!(Topology1.spouts + Topology1.bolts)

      Topology1.spouts.first.id.should == 1
      Topology1.bolts.first.id.should == 2
      Topology1.bolts.first.sources.first.should == [1, {:shuffle => nil}]
    end

    it "should raise on unresolvable" do
      class Topology1 < RedStorm::SimpleTopology
        spout SpoutClass1

        bolt BoltClass1 do
          source "dummy", :shuffle
        end
      end
      
      Topology1.spouts.first.id.should == "spout_class1"
      Topology1.bolts.first.id.should == "bolt_class1"
      Topology1.bolts.first.sources.first.should == ["dummy", {:shuffle => nil}]

      lambda {Topology1.resolve_ids!(Topology1.spouts + Topology1.bolts)}.should raise_error RuntimeError, "cannot resolve BoltClass1 source id=dummy"
    end

    it "should raise on duplicate conflict" do
      class Topology1 < RedStorm::SimpleTopology
        spout SpoutClass1
        spout SpoutClass1
      end
      
      Topology1.spouts.first.id.should == "spout_class1"
      Topology1.spouts.last.id.should == "spout_class1"

      lambda {Topology1.resolve_ids!(Topology1.spouts)}.should raise_error RuntimeError, "duplicate symbolic id in SpoutClass1 on id=spout_class1"
    end

  end
end