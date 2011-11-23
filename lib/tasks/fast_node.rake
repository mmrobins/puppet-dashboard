namespace :node do
  desc 'Remove a node - custom SQL for those who do not have cascading deletes from #6717 in place yet'
  task :fast_del => :environment do
    # Node deletion is really slow in the current version of dashboard because
    # it uses destroy instead of delete which creates a new activerecord model for every record
    # This has been fixed in the current code base, but not yet released.
    # This task is a stopgap until then and will never actually be merged in
    # Always remember to backup your data before running this
    if ENV['name']
      name = ENV['name']
    else
      puts 'Must specify node name (name=<hostname>).'
      exit 1
    end

    begin
      n = Node.find_by_name(name)

      node_where_clause = "where n.id = #{n.id}"
      node_report_join_clause = <<-SQL
        inner join reports r on r.id = my_table.report_id
        inner join nodes n on n.id = r.node_id
      SQL

      puts "Deleting resource_events"
      ActiveRecord::Base.connection.execute(<<-SQL
        delete
          re
        from
          resource_events re
          inner join resource_statuses my_table on my_table.id = re.resource_status_id
          #{node_report_join_clause}
        #{node_where_clause}
      SQL
      )

      %w{resource_statuses metrics report_logs}.each do |table|
        puts "Deleting #{table}"
        ActiveRecord::Base.connection.execute(<<-SQL
          delete
            my_table
          from
            #{table} my_table
            #{node_report_join_clause}
          #{node_where_clause}
        SQL
        )
      end

      puts "Deleting reports"
      ActiveRecord::Base.connection.execute(<<-SQL
        delete
          r
        from
          reports r inner join nodes n on r.node_id = n.id
        #{node_where_clause}
      SQL
      )

      puts "Deleting node"
      n.destroy
    rescue NoMethodError
      puts 'Node does not exist!'
      exit 1
    rescue => e
      puts e.message
      exit 1
    end
  end
end
