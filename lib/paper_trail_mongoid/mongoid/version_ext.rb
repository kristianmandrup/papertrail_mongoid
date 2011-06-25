# Adds a #find_next_version method to the Mongoid versioning module

module Mongoid
  module Versioning
    extend ActiveSupport::Concern

    def revise_previous_trail_version
      prev = trail_version - 1
      puts "PREV: #{prev}"
      prev = prev > 0 ? prev : 1 
      clone_trail_version(versions.where(:version => prev).first)
    end
    
    def revise_next_trail_version
      nxt = trail_version + 1
      puts "NXT: #{nxt}"
      nxt = nxt > 0 ? nxt : 1
      nxt = nxt < (trail_version - 1) ? nxt : 1       
      clone_trail_version(versions.where(:version => nxt).first)
    end

    def clone_trail_version src_obj
      versions.target << src_obj.clone
      versions.shift if version_max.present? && versions.length > version_max
      self.trail_version = (trail_version || 1 ) + 1
      @modifications["versions"] = [ nil, versions.as_document ] if @modifications
      src_obj
    end
  end
end
    