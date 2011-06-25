module PaperTrailing  
  class NotRevisableError < StandardError; end

  # def self.with_item_keys(item_type, item_id)
  #   scoped(:conditions => { :item_type => item_type, :item_id => item_id })
  # end

  # Restore this version.

  def reify(options = {})
    revise if revisable?
    raise NotRevisableError if !revisable?
  end    

  # Returns who put the item into the state stored in this version.
  def originator
    previous.try :whodunnit
  end

  # Returns who changed the item from the state it had in this version.
  # This is an alias for `whodunnit`.
  def terminator
    whodunnit
  end

  def sibling_versions
    versions
  end

  def next
    revise_next_trail_version
  end

  def previous
    revise_previous_trail_version
  end

  def index
    # In Mongoid, normally the class is Indexed on one or more attributes!
    ordered_versions.map(&:_id) #.index("id")
  end
  
  protected
  
  def ordered_versions
    sibling_versions.asc(:version)
  end  
end
