class NodeGroupsController < InheritedResources::Base
  respond_to :html, :json
  before_filter :raise_unless_using_external_node_classification
  before_filter :raise_if_enable_read_only_mode, :only => [:new, :edit, :create, :update, :destroy]

  include SearchableIndex

  def diff_latest_against_own_baselines
    @node_group = NodeGroup.find(params[:id])

    @node_diffs = {}
    @node_group.nodes.each do |node|
      next unless node.baseline_report && node.last_inspect_report
      @node_diffs[node.name] = node.baseline_report.diff(node.last_inspect_report)
    end
  end
end
