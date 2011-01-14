require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'shared_behaviors/controller_mixins'
require 'shared_behaviors/sorted_index'

describe NodeGroupsController do
  integrate_views
  def model; NodeGroup end

  it_should_behave_like "without JSON pagination"
  it_should_behave_like "with search by q and tag"
  it_should_behave_like "sorted index"

  describe "when diffing latest inspect report against baseline" do
    before :each do
      @node_group = NodeGroup.generate!
      @node = Node.generate! :name => "node_it_all"
      @node_group.nodes << @node

      @report1 = Report.generate!(:host => @node.name, :kind => 'inspect', :time => 2.hours.ago)
      @resource_status1 = ResourceStatus.generate!(
        :report        => @report1,
        :resource_type => 'File',
        :title         => '/tmp/test'
      )

      @report2 = Report.generate!(:host => @node.name, :kind => 'inspect', :time => 1.hour.ago)
      @resource_status2 = ResourceStatus.generate!(
        :report        => @report2,
        :resource_type => 'File',
        :title         => '/tmp/test'
      )
    end

    it "should not produce a node diff if the node doesn't have a baseline or latest inspect report" do
      get :diff_latest_against_own_baselines, :id => @node_group.id
      response.should be_success
      assigns[:node_diffs].should be_empty
    end

    it "should not produce a node diff if the node doesn't have any differences" do
      @node.reports = [@report1, @report2]
      @report1.baseline!
      @node.last_inspect_report = @report2

      @resource_event1 = ResourceEvent.generate!(
        :resource_status => @resource_status1,
        :property        => 'content',
        :previous_value  => '{md5}0b8b61ed7bce7ffb93cedc19845468cc'
      )

      @resource_event2 = ResourceEvent.generate!(
        :resource_status => @resource_status2,
        :property        => 'content',
        :previous_value  => '{md5}0b8b61ed7bce7ffb93cedc19845468cc'
      )

      get :diff_latest_against_own_baselines, :id => @node_group.id
      response.should be_success
#     assigns[:nodes_with_diffs].should be_empty
#     assigns[:node_without_diffs].should == [@node]
    end

    it "should organize diffs by node" do
      @node.reports = [@report1, @report2]
      @report1.baseline!
      @node.last_inspect_report = @report2

      @resource_event1 = ResourceEvent.generate!(
        :resource_status => @resource_status1,
        :property        => 'content',
        :previous_value  => '{md5}abcd'
      )

      @resource_event2 = ResourceEvent.generate!(
        :resource_status => @resource_status2,
        :property        => 'content',
        :previous_value  => '{md5}efgh'
      )

      get :diff_latest_against_own_baselines, :id => @node_group.id
      response.should be_success
      assigns[:node_diffs].should == {"node_it_all"=>{"File[/tmp/test]"=>{:content=>["{md5}abcd", "{md5}efgh"]}}}
    end
  end
end
