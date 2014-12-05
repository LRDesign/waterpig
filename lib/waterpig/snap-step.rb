module Waterpig
  module SnapStep
    def self.included(steps)
      steps.after(:step) do |example|
        save_snapshot(example.metadata[:snapshots_into], example.description.downcase.gsub(/\s+/, "-"))
      end
    end
  end

  module AutoSnap
    def self.included(group)
      description_args = group.metadata[:description_args] || group[:example_group][:description_args]
      group.metadata[:snapshots_into] = description_args.first.downcase.gsub(/\W+/, "_").sub(/^_*/,'').sub(/_*$/,'')
    end
  end
end
