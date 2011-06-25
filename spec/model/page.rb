class Page
  include PaperTrail::Model

  include Mongoid::Document
  
  field :number,  :type => Integer, :default => 0
  field :title,   :type => String
  field :text,    :type => String  
  
  has_paper_trail
end