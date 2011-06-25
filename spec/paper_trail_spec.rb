require 'spec_helper'

describe PaperTrail do
  it 'should be a Module' do
    PaperTrail.should be_a(Module)    
  end

  context 'A single page' do
    before do
      @page = Page.create :title => 'hello'
      @page.title = 'goodbye'
      @page.save!
    end

    describe '#version' do        
      it 'should point to current version number: 2' do
        @page.version.should == 2        
      end 
      
      it 'should have trail version: 1' do      
        @page.trail_version.should == 1
      end
    end

    describe '#previous' do
      it 'should return the same version = 2' do
        prev = @page.previous        
        prev.version.should == 2
      end 
      
      it 'should have trail version: 1' do
        @page.trail_version.should == 1
      end
    end
    
    describe '#next' do
      it 'should return the same version = 2' do
        nxt = @page.next
        nxt.version.should == 2
      end 
      
      it 'should have trail version: 1' do
        @page.trail_version.should == 3
      end      
    end
  end

  # context 'page modified and saved twice' do
  #   before do
  #     @page = Page.create :title => 'hello'
  #     @page.title = 'goodbye'
  #     @page.save!
  #     puts "After page changed and saved"
  #     pp @page.versions
  #     @page.title = 'goodbye again'
  #     puts "After page changed without save"
  #     pp @page.versions      
  #   end
  #   
  #   describe '#version' do
  #     it 'should initially have version 2' do
  #       @page.version.should == 2
  #     end 
  #   end
  #   
  #   describe '#previous of page' do
  #     it 'should return previous version' do
  #       @page.version.should == 2
  #       @page.save!
  #       puts "After save"
  #       pp @page.versions
  #       puts @page.version
  #       @page.title = 'adios'
  #       # pp @page.previous
  #       # pp @page
  #       # @page.previous.version.should == 2
  #       @page.save!      
  #       puts "ALL"
  #       pp @page.versions
  #       pp @page.versions.where(:version => 1).first        
  #       pp @page.versions.where(:version => 2).first                
  #     end 
  #   end
  #   
  # end

  # context '2 pages' do
  #   before do
  #     @page1 = Page.create
  #     pp @page1   
  #     @page1.save!
  #     pp Page.all.to_a      
  #     @page1.title = 'changed to page2'
  #     puts "after change"
  #     pp Page.all.to_a      
  #     @page1.save!
  #     
  #     puts "after save"
  #     pp Page.all.to_a
  #   end
  # 
  #   describe '#version' do
  #     it 'should initially have version 2' do
  #       @page1.version.should == 2
  #     end 
  #   end
  # 
  #   describe '#previous of page 2' do
  #     it 'should return page 1' do
  #       @page1.version.should == 2
  #       prev = @page1.previous        
  #       pp prev
  #       prev.version.should == 1
  #     end 
  #   end
    # 
    # describe '#next of page 1' do
    #   it 'should return page 2' do
    #     @page1.next.number.should == 2
    #   end 
    # end
    # 
    # describe '#reify of page 2' do
    #   it 'should return page 1 as current version' do
    #     @page2.title = 'Changed it' # must be changed first in order to be revisable !!!
    #     @page2.reify.number.should == 1
    #     Page.last.number.should == 1
    #   end 
    # end
    # 
    # describe 'versions destroyed' do
    #   it 'should destroy top version each time' do
    #     @page2.title = 'Changed it again'
    #     @page2.reify.number.should == 1 # numbers: 1,2,1
    # 
    #     Page.last.number.should == 1
    #     Page.last.destroy # numbers: 1,2
    #     Page.last.number.should == 2
    #     Page.last.destroy # numbers: 1
    #     Page.last.number.should == 1
    #   end 
    # end
  # end
end
  