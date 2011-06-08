class PagesController < ApplicationController
  def home
    @nodes = Node.unhidden

    @unreported_nodes          = @nodes.unreported

    @unresponsive_nodes       = @nodes.unresponsive
    @failed_nodes             = @nodes.failed
    @pending_nodes            = @nodes.pending
    @changed_nodes            = @nodes.changed
    @unchanged_nodes          = @nodes.unchanged
  end

  def release_notes
  end
end
