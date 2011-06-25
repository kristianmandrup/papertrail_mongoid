# PaperTrail for Mongoid

See [Mongoid versioning rundown](http://neovintage.blogspot.com/2010/06/mongoid-versioning-run-down.html)

Also see the file _mongoid_versioning.txt.rb_ to see the Mongoid versioning API used here.

PaperTrail lets you track changes to your models' data.  It's good for auditing or versioning.  You can see how a model looked at any stage in its lifecycle, revert it to any version, and even undelete it after it's been destroyed.

There's an excellent [Railscast on implementing Undo with Paper Trail](http://railscasts.com/episodes/255-undo-with-paper-trail).

## Status May, 2011

I am using RSpec to spec the functionality. As per May 6th I am just experimenting but most of the functionality should be pretty close, as the whole versioning aspect is much easier in the Mongoid data model, using a JSON document model for storage. Please help out! 

Now I'm using a custom field #trail_version to track the paper trail. 
The paper_trail functionality should be updated to use this attribute instead of the version attribute. See version_ext for my plan for how to access any previous version based on the #trail_version number. The #next and #previous methods should act relative to that number and then make a clone.
Currently something like the following:

  def clone_trail_version src_obj
    versions.target << src_obj.clone
    versions.shift if version_max.present? && versions.length > version_max
    self.trail_version = (trail_version || 1 ) + 1
    @modifications["versions"] = [ nil, versions.as_document ] if @modifications
    src_obj
  end

## Features

* Stores every create, update and destroy.
* Does not store updates which don't change anything.
* Allows you to specify attributes (by inclusion or exclusion) which must change for a Version to be stored.
* Allows you to get at every version, including the original, even once destroyed.
* Allows you to get at every version even if the schema has since changed.
* Allows you to get at the version as of a particular time.
* Automatically restores the `has_one` associations as they were at the time.
* Automatically records who was responsible via your controller.  PaperTrail calls `current_user` by default, if it exists, but you can have it call any method you like.
* Allows you to set who is responsible at model-level (useful for migrations).
* Allows you to store arbitrary model-level metadata with each version (useful for filtering versions).
* Allows you to store arbitrary controller-level information with each version, e.g. remote IP.
* Can be turned off/on per class (useful for migrations).
* Can be turned off/on per request (useful for testing with an external service).
* Can be turned off/on globally (useful for testing).
* No configuration necessary.
* Stores everything in a single database table by default (generates migration for you), or can use separate tables for separate models.
* Supports custom version classes so different models' versions can have different behaviour.
* Thoroughly tested.
* Threadsafe.

## Rails Version

Works on Rails 3 (Rails 2.3 not tested)

## API Summary

When you declare `has_paper_trail` in your model, you get these methods:

    class Widget
      include Mongoid::Document
      has_paper_trail   # you can pass various options here
    end

    # Returns this widget's versions.
    widget.versions

    # Return the version this widget was reified from, or nil if it is live.
    widget.version

    # Returns true if this widget is the current, live one; or false if it is from a previous version.
    widget.live?

    # Returns who put the widget into its current state.
    widget.originator

    # Returns the widget (not a version) as it looked at the given timestamp.
    widget.version_at(timestamp)

    # Returns the widget (not a version) as it was most recently.
    widget.previous_version

    # Returns the widget (not a version) as it became next.
    widget.next_version

    # Turn PaperTrail off for all widgets.
    Widget.paper_trail_off

    # Turn PaperTrail on for all widgets.
    Widget.paper_trail_on

And a `Version` instance has these methods:

    # Returns the item restored from this version.
    version.reify(options = {})

    # Returns who put the item into the state stored in this version.
    version.originator

    # Returns who changed the item from the state it had in this version.
    version.terminator
    version.whodunnit

    # Returns the next version.
    version.next

    # Returns the previous version.
    version.previous

    # Returns the index of this version in all the versions.
    version.index

    # Returns the event that caused this version (create|update|destroy).
    version.event

In your controllers you can override these methods:

    # Returns the user who is responsible for any changes that occur.
    # Defaults to current_user.
    user_for_paper_trail

    # Returns any information about the controller or request that you want
    # PaperTrail to store alongside any changes that occur.
    info_for_paper_trail


## Basic Usage

PaperTrail is simple to use.  Just add 15 characters to a model to get a paper trail of every `create`, `update`, and `destroy`.

    class Widget
      include Mongoid::Document
      has_paper_trail
    end

This gives you a `versions` method which returns the paper trail of changes to your model.

    >> widget = Widget.find 42
    >> widget.versions             # [<Version>, <Version>, ...]

Once you have a version, you can find out what happened:

    >> v = widget.versions.last
    >> v.event                     # 'update' (or 'create' or 'destroy')
    >> v.whodunnit                 # '153'  (if the update was via a controller and
                                   #         the controller has a current_user method,
                                   #         here returning the id of the current user)
    >> v.created_at                # when the update occurred
    >> widget = v.reify            # the widget as it was before the update;
                                   # would be nil for a create event

PaperTrail stores the pre-change version of the model, unlike some other auditing/versioning plugins, so you can retrieve the original version.  This is useful when you start keeping a paper trail for models that already have records in the database.

    >> widget = Widget.find 153
    >> widget.name                                 # 'Doobly'

    # Add has_paper_trail to Widget model.

    >> widget.versions                             # []
    >> widget.update_attributes :name => 'Wotsit'
    >> widget.versions.first.reify.name            # 'Doobly'
    >> widget.versions.first.event                 # 'update'

This also means that PaperTrail does not waste space storing a version of the object as it currently stands.  The `versions` method gives you previous versions; to get the current one just call a finder on your `Widget` model as usual.

Here's a helpful table showing what PaperTrail stores:

<table>
  <tr>
    <th>Event</th>
    <th>Model Before</th>
    <th>Model After</th>
  </tr>
  <tr>
    <td>create</td>
    <td>nil</td>
    <td>widget</td>
  </tr>
  <tr>
    <td>update</td>
    <td>widget</td>
    <td>widget'</td>
  <tr>
    <td>destroy</td>
    <td>widget</td>
    <td>nil</td>
  </tr>
</table>

PaperTrail stores the values in the Model Before column.  Most other auditing/versioning plugins store the After column.


## Choosing Attributes To Monitor

You can ignore changes to certain attributes like this:

    class Article
      include Mongoid::Document
      has_paper_trail :ignore => [:title, :rating]
    end

This means that changes to just the `title` or `rating` will not store another version of the article.  It does not mean that the `title` and `rating` attributes will be ignored if some other change causes a new `Version` to be crated.  For example:

    >> a = Article.create
    >> a.versions.length                         # 1
    >> a.update_attributes :title => 'My Title', :rating => 3
    >> a.versions.length                         # 1
    >> a.update_attributes :content => 'Hello'
    >> a.versions.length                         # 2
    >> a.versions.last.reify.title               # 'My Title'

Or, you can specify a list of all attributes you care about:

    class Article
      include Mongoid::Document
      has_paper_trail :only => [:title]
    end

This means that only changes to the `title` will save a version of the article:

    >> a = Article.create
    >> a.versions.length                         # 1
    >> a.update_attributes :title => 'My Title'
    >> a.versions.length                         # 2
    >> a.update_attributes :content => 'Hello'
    >> a.versions.length                         # 2

Passing both `:ignore` and `:only` options will result in the article being saved if a changed attribute is included in `:only` but not in `:ignore`.


## Reverting And Undeleting A Model

PaperTrail makes reverting to a previous version easy:

    >> widget = Widget.find 42
    >> widget.update_attributes :name => 'Blah blah'
    # Time passes....
    >> widget = widget.versions.last.reify  # the widget as it was before the update
    >> widget.save                          # reverted

Alternatively you can find the version at a given time:

    >> widget = widget.version_at(1.day.ago)  # the widget as it was one day ago
    >> widget.save                            # reverted

Note `version_at` gives you the object, not a version, so you don't need to call `reify`.

Undeleting is just as simple:

    >> widget = Widget.find 42
    >> widget.destroy
    # Time passes....
    >> widget = Version.find(153).reify    # the widget as it was before it was destroyed
    >> widget.save                         # the widget lives!

In fact you could use PaperTrail to implement an undo system, though I haven't had the opportunity yet to do it myself.  However [Ryan Bates has](http://railscasts.com/episodes/255-undo-with-paper-trail)!


## Navigating Versions

You can call `previous_version` and `next_version` on an item to get it as it was/became.  Note that these methods reify the item for you.

    >> widget = Widget.find 42
    >> widget.versions.length              # 4 for example
    >> widget = widget.previous_version    # => widget == widget.versions.last.reify
    >> widget = widget.previous_version    # => widget == widget.versions[-2].reify
    >> widget.next_version                 # => widget == widget.versions.last.reify
    >> widget.next_version                 # nil

As an aside, I'm undecided about whether `widget.versions.last.next_version` should return `nil` or `self` (i.e. `widget`).  Let me know if you have a view.

If instead you have a particular `version` of an item you can navigate to the previous and next versions.

    >> widget = Widget.find 42
    >> version = widget.versions[-2]    # assuming widget has several versions
    >> previous = version.previous
    >> next = version.next

You can find out which of an item's versions yours is:

    >> current_version_number = version.index    # 0-based

Finally, if you got an item by reifying one of its versions, you can navigate back to the version it came from:

    >> latest_version = Widget.find(42).versions.last
    >> widget = latest_version.reify
    >> widget.version == latest_version    # true

You can find out whether a model instance is the current, live one -- or whether it came instead from a previous version -- with `live?`:

    >> widget = Widget.find 42
    >> widget.live?                        # true
    >> widget = widget.versions.last.reify
    >> widget.live?                        # false


## Finding Out Who Was Responsible For A Change

If your `ApplicationController` has a `current_user` method, PaperTrail will store the value it returns in the `version`'s `whodunnit` column.  Note that this column is a string so you will have to convert it to an integer if it's an id and you want to look up the user later on:

    >> last_change = Widget.versions.last
    >> user_who_made_the_change = User.find last_change.whodunnit.to_i

You may want PaperTrail to call a different method to find out who is responsible.  To do so, override the `user_for_paper_trail` method in your controller like this:

    class ApplicationController
      def user_for_paper_trail
        logged_in? ? current_member : 'Public user'  # or whatever
      end
    end

In a migration or in `script/console` you can set who is responsible like this:

    >> PaperTrail.whodunnit = 'Andy Stewart'
    >> widget.update_attributes :name => 'Wibble'
    >> widget.versions.last.whodunnit              # Andy Stewart

N.B. A `version`'s `whodunnit` records who changed the object causing the `version` to be stored.  Because a `version` stores the object as it looked before the change (see the table above), `whodunnit` returns who stopped the object looking like this -- not who made it look like this.  Hence `whodunnit` is aliased as `terminator`.

To find out who made a `version`'s object look that way, use `version.originator`.  And to find out who made a "live" object look like it does, use `originator` on the object.

    >> widget = Widget.find 153                    # assume widget has 0 versions
    >> PaperTrail.whodunnit = 'Alice'
    >> widget.update_attributes :name => 'Yankee'
    >> widget.originator                           # 'Alice'
    >> PaperTrail.whodunnit = 'Bob'
    >> widget.update_attributes :name => 'Zulu'
    >> widget.originator                           # 'Bob'
    >> first_version, last_version = widget.versions.first, widget.versions.last
    >> first_version.whodunnit                     # 'Alice'
    >> first_version.originator                    # nil
    >> first_version.terminator                    # 'Alice'
    >> last_version.whodunnit                      # 'Bob'
    >> last_version.originator                     # 'Alice'
    >> last_version.terminator                     # 'Bob'


## Custom Version Classes

Not needed when using Mongoid

## Associations

Handled by Mongoid as everything is just a document

## Has-One Associations

Handled by Mongoid ?

## Has-Many-Through Associations

Handled by Mongoid ?

## Storing metadata

You can store arbitrary model-level metadata alongside each version like this:

    class Article < ActiveRecord::Base
      belongs_to :author
      has_paper_trail :meta => { :author_id  => Proc.new { |article| article.author_id },
                                 :word_count => :count_words,
                                 :answer     => 42 }
      def count_words
        153
      end
    end

Hmm.. In Mongo you can always add extra fields to the data stored for a record - flexible schema!

## Diffing Versions

Just compare the JSON - done internally by Mongoid when doing == ?

## Turning PaperTrail Off/On

Sometimes you don't want to store changes.  Perhaps you are only interested in changes made by your users and don't need to store changes you make yourself in, say, a migration -- or when testing your application.

You can turn PaperTrail on or off in three ways: globally, per request, or per class.

### Globally

On a global level you can turn PaperTrail off like this:

    >> PaperTrail.enabled = false

For example, you might want to disable PaperTrail in your Rails application's test environment to speed up your tests.  This will do it:

    # in config/environments/test.rb
    config.after_initialize do
      PaperTrail.enabled = false
    end

If you disable PaperTrail in your test environment but want to enable it for specific tests, you can add a helper like this to your test helper:

    # in test/test_helper.rb
    def with_versioning
      was_enabled = PaperTrail.enabled?
      PaperTrail.enabled = true
      begin
        yield
      ensure
        PaperTrail.enabled = was_enabled
      end
    end

And then use it in your tests like this:

    test "something that needs versioning" do
      with_versioning do
        # your test
      end
    end

### Per request

You can turn PaperTrail on or off per request by adding a `paper_trail_enabled_for_controller` method to your controller which returns true or false:

    class ApplicationController < ActionController::Base
      def paper_trail_enabled_for_controller
        request.user_agent != 'Disable User-Agent'
      end
    end

### Per class

If you are about change some widgets and you don't want a paper trail of your changes, you can turn PaperTrail off like this:

    >> Widget.paper_trail_off

And on again like this:

    >> Widget.paper_trail_on



## Deleting Old Versions

Over time your `versions` table will grow to an unwieldy size.  Because each version is self-contained (see the Diffing section above for more) you can simply delete any records you don't want any more.  For example:

    sql> delete from versions where created_at < 2010-06-01;

    >> Version.delete_all ["created_at < ?", 1.week.ago]


## Installation

### Rails 3

1. Install PaperTrail as a gem via your `Gemfile`:

    `gem 'paper_trail', '~> 2'`

2. Generate a migration which will add a `versions` table to your database.

    `bundle exec rails generate paper_trail:install`

3. Run the migration.

    `bundle exec rake db:migrate`

4. Add `has_paper_trail` to the models you want to track.

### Rails 2

Please see the `rails2` branch.


## Testing

PaperTrail uses Bundler to manage its dependencies (in development and testing).  You can run the tests with `bundle exec rake test`.  (You may need to `bundle install` first.)


## Articles

[Keep a Paper Trail with PaperTrail](http://www.linux-mag.com/id/7528), Linux Magazine, 16th September 2009.


## Problems

Please use GitHub's [issue tracker](http://github.com/airblade/paper_trail/issues).


## Contributors

Many thanks to:

* [Zachery Hostens](http://github.com/zacheryph)
* [Jeremy Weiskotten](http://github.com/jeremyw)
* [Phan Le](http://github.com/revo)
* [jdrucza](http://github.com/jdrucza)
* [conickal](http://github.com/conickal)
* [Thibaud Guillaume-Gentil](http://github.com/thibaudgg)
* Danny Trelogan
* [Mikl Kurkov](http://github.com/mkurkov)
* [Franco Catena](https://github.com/francocatena)
* [Emmanuel Gomez](https://github.com/emmanuel)
* [Matthew MacLeod](https://github.com/mattmacleod)
* [benzittlau](https://github.com/benzittlau)
* [Tom Derks](https://github.com/EgoH)
* [Jonas Hoglund](https://github.com/jhoglund)
* [Stefan Huber](https://github.com/MSNexploder)
* [thinkcast](https://github.com/thinkcast)
* [kristianmandrup](https://github.com/kristianmandrup)


## Inspirations

* [Simply Versioned](http://github.com/github/simply_versioned)
* [Acts As Audited](http://github.com/collectiveidea/acts_as_audited)


## Intellectual Property

Copyright (c) 2011 Andy Stewart (boss@airbladesoftware.com).
Released under the MIT licence.
