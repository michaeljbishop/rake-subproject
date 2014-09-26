# Rake::Subproject

If you have a project for which you've built a Rakefile and it includes a subproject
which has its own Rakefile, you can 'bridge' the subproject into the super project
with a single line: 'subproject(dir)'. With this in place, all the subproject's
tasks can be called in the super project.

Here's what it looks like:

### Rakefile

```ruby
require 'rake/subproject'

subproject 'foo'

task :clean => 'foo:clean'

task :default => ['foo/bar', 'foo:bar:baz']
```

### foo/Rakefile

```ruby
require 'rake/clean'

file 'bar' do |t|
  touch t.name
end

CLEAN.include 'bar'

namespace 'bar' do
  task 'baz' do
    $stdout.puts "SUCCESS"
  end
end
```

Now, let's execute the top-level Rakefile **twice**:

```
$ find .
.
./foo
./foo/Rakefile
./Rakefile
$ rake
touch bar
SUCCESS
$ find .
.
./foo
./foo/bar
./foo/Rakefile
./Rakefile
$ rake
SUCCESS
$ rake clean
$ rake
touch bar
SUCCESS
$ rake foo:bar:baz
SUCCESS
```

There are some interesting things to observe:

1. The task `foo/bar` was only executed the first time because:

    1. It was a FileTask and
    2. the first time created it so the second time it was skipped

2. The namespace `foo:` passes through to the subproject and calls the
task locally there.

3. The file `bar` is created relative to the *subproject* even though we are calling
it from the *super-project*

4. The `:clean` task is bridged into the subproject's `:clean` task
5. We can directly call `foo:bar:baz` from the command-line

## Installation

Add this line to your application's Gemfile:

    gem 'rake-subproject'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rake-subproject

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( http://github.com/<my-github-username>/rake-subproject/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
