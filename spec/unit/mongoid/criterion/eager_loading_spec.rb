require "spec_helper"

describe Mongoid::Criterion::EagerLoading do

  describe "#includes" do
    
    it "should return self" do
      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:game, :posts).should == criteria
    end

    it "set eager loadings" do
      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:game, :posts)
      criteria.eager_loadings.should == [:game, :posts]
    end
  end

  describe "#preload" do
    let(:person1) { Person.create(:title => "Sir", :age => 100, :aliases => ["D", "Durran"], :ssn => "666666666") }
    let(:person2) { Person.create(:title => "Madam", :age => 1, :ssn => "098-76-5434") }

    before do
      person1.create_game(:score => 10)
      person2.create_game(:score => 20)
      
      person1.posts.create(:title => "post1")
      person1.posts.create(:title => "post2")
      person2.posts.create(:title => "post3")
      person2.posts.create(:title => "post4")
      
      person1.preferences.create(:name => "preference1")
      person1.preferences.create(:name => "preference2")
      person2.preferences.create(:name => "preference3")
      person2.preferences.create(:name => "preference4")
    end

    it "preload references_one association" do
      complex = stub(:key => :person_id, :operator => "in")
      Mongoid::Criterion::Complex.expects(:new).with(:key => :person_id, :operator => "in").returns(complex)
      Game.expects(:where).with(complex => [person1.id, person2.id]).returns([person1.game, person2.game])
      
      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:game)
      criteria.preload([person1, person2])
    end

    it "preload references_many association" do
      complex = stub(:key => :person_id, :operator => "in")
      Mongoid::Criterion::Complex.expects(:new).with(:key => :person_id, :operator => "in").returns(complex)
      Post.expects(:where).with(complex => [person1.id, person2.id]).returns(person1.posts + person2.posts)
      
      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:posts)
      criteria.preload([person1, person2])
    end

    it "preload references_many_as_array association" do
      Preference.expects(:find).with((person1.preferences + person2.preferences).collect(&:id)).returns(person1.preferences + person2.preferences)

      criteria = Mongoid::Criteria.new(Person)
      criteria.includes(:preferences)
      criteria.preload([person1, person2])
    end

    it "preload referenced_in association" do
      Person.expects(:find).with([person1.id, person2.id]).returns([person1, person2])
      
      criteria = Mongoid::Criteria.new(Game)
      criteria.includes(:person)
      criteria.preload([person1.game, person2.game])
    end
  end
end