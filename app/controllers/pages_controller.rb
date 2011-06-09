class PagesController < ApplicationController
  def home
    @all_nodes = Node.unhidden

    @unreported_nodes         = @all_nodes.unreported
    @recently_reported_nodes  = @all_nodes.by_report_date
    @unresponsive_nodes       = @all_nodes.unresponsive
    @failed_nodes             = @all_nodes.failed
    @pending_nodes            = @all_nodes.pending
    @changed_nodes            = @all_nodes.changed
    @unchanged_nodes          = @all_nodes.unchanged
  end

  def release_notes
  end
end
