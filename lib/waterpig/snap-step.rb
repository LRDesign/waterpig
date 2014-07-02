module Waterpig
  module SnapStep
    def self.included(steps)
      steps.after(:step) do
        save_snapshot(example.metadata[:snapshots_into], example.description.downcase.gsub(/\s+/, "-"))
      end
    end
  end

  module AutoSnap
    def self.included(group)
      group.metadata[:snapshots_into] = group.metadata[:example_group][:description_args].first.downcase.gsub(/\W+/, "_").sub(/^_*/,'').sub(/_*$/,'')
    end
  end
end
