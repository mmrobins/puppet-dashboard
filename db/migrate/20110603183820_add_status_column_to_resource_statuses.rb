class AddStatusColumnToResourceStatuses < ActiveRecord::Migration
  def self.up
    add_column :resource_statuses, :status, :string

    pending_count = 0
    unchanged_count = 0

    # only going to update last report for each node since that's what people will care most about for counts
    Node.all.each do |n|
      require 'ruby-debug'; debugger; 1;
      n.last_apply_report.resource_statuses.each do |rs|
        if rs.events.any? {|e| e.status == 'failure'}
          rs.status = 'failed'
        elsif rs.events.any? {|e| e.status == 'noop'}
          rs.status = 'pending'
          pending_count += 1
        elsif rs.events.any? {|e| e.status == 'success'}
          rs.status = 'changed'
        else
          rs.status = 'unchanged'
          unchanged_count += 1
        end
        rs.save
      end
      n.last_apply_report.metrics.create(:category => 'resources', :name => 'pending', :value => pending_count)
      n.last_apply_report.metrics.create(:category => 'resources', :name => 'unchanged', :value => unchanged_count)
    end
  end

  def self.down
    remove_column :resource_statuses, :status
  end
end
