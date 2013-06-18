require 'java'
require 'spec_helper'

require 'red_storm/dsl/tuple'

java_import 'backtype.storm.Testing'
java_import 'backtype.storm.tuple.Values'

describe "Tuple" do

  it "should return value by index" do
    tuple = Testing.testTuple(Values.new("james", "bond"))
    tuple[0].should == "james"
    tuple[1].should == "bond"
    lambda {tuple[2]}.should raise_error
  end

  it "should return value by field string" do
    tuple = Testing.testTuple(Values.new("james", "bond"))
    tuple["field1"].should == "james"
    tuple["field2"].should == "bond"
    lambda {tuple["field3"]}.should raise_error
  end

  it "should return value by field symbol" do
    tuple = Testing.testTuple(Values.new("james", "bond"))
    tuple[:field1].should == "james"
    tuple[:field2].should == "bond"
    lambda {tuple[:field3]}.should raise_error
  end

  it "should return field_index with field string" do
    tuple = Testing.testTuple(Values.new("james", "bond"))
    tuple.field_index("field1").should == 0
    tuple.field_index("field2").should == 1
    lambda {tuple.field_index("field3")}.should raise_error
  end

  it "should return field_index with field symbol" do
    tuple = Testing.testTuple(Values.new("james", "bond"))
    tuple.field_index(:field1).should == 0
    tuple.field_index(:field2).should == 1
    lambda {tuple.field_index(:field3)}.should raise_error
  end

  it "should return contains? with field string" do
    tuple = Testing.testTuple(Values.new("james", "bond"))
    tuple.contains?("field1").should be_true
    tuple.contains?("field2").should be_true
    tuple.contains?("field3").should be_false
  end

  it "should return contains? with field symbol" do
    tuple = Testing.testTuple(Values.new("james", "bond"))
    tuple.contains?(:field1).should be_true
    tuple.contains?(:field2).should be_true
    tuple.contains?(:field3).should be_false
  end
end
