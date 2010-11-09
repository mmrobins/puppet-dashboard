class AddStatusToReports < ActiveRecord::Migration
  class Report < ActiveRecord::Base
    delegate :failed?, :changed?, :to => :report
    serialize :report, Puppet::Transaction::Report

    def report
      rep = read_attribute(:report)
      rep.extend(ReportExtensions) unless rep.nil? or rep.is_a?(ReportExtensions)
      rep
    end
  end

  def self.up
    add_column :reports, :status, :string
    add_index :reports, [:time, :node_id, :status]
    Report.all.each do |report|
      report.status = report.failed? ? 'failed' : report.changed? ? 'changed' : 'unchanged'
      report.save
    end
    remove_index :reports, [:time, :node_id, :success]
    remove_column :reports, :success

    add_column :nodes, :status, :string
    Node.all.each do |node|
      node.status = node.last_report ? node.last_report.status : 'unchanged'
      node.save
    end
    remove_column :nodes, :success
  end

  def self.down
    add_column :reports, :success, :boolean
    add_index :reports, [:time, :node_id, :success]
    Report.all.each do |report|
      report.success = report.status != "failed"
      report.save
    end
    remove_index :reports, [:time, :node_id, :status]
    remove_column :reports, :status

    add_column :nodes, :success, :boolean, :default => false
    Node.all.each do |node|
      node.success = node.last_report ? node.last_report.success : false
      node.save
    end
    remove_column :nodes, :status
  end
end
