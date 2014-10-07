module Rake::DSL
  # Bridges the subproject's tasks to within the current Rakefile.
  # Tasks from the sub-project can be referenced in the super-project by
  # prefixing the sub-project task with the namespace of its containing directory.
  #
  # For example, given a project in a subdirectory, '+foo+':
  #
  # +foo/Rakefile+:
  #   task :bar
  #
  # The super project can include it via the #subproject call and reference the
  # subproject's tasks via a namespace or via a path:
  #
  # +Rakefile+:
  #
  #   require 'rake/subproject'
  #
  #   subproject 'foo' 
  #
  #   task :first  => foo:bar # valid reference
  #   task :second => foo/bar # valid reference
  #
  # The +path+ parameter can be either a *directory* containing a valid Rakefile or a path
  # to a specific *file*.
  # 
  # Given a directory::
  #
  #   It cannot be to a subdirectory whose superdirectory contains a Rakefile. The
  #   subdirectory itself must contain the Rakefile. The namespace is
  #   generated from the directory path.
  #
  # Given a file::
  #
  #   The namespace is generated from the directory containing the file.
  #
  def subproject(path)
    Rake.application.define_subproject(path)
  end
end
