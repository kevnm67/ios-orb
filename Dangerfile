# frozen_string_literal: true

# set the files to watch and warn about if there are changes made
@ci_files = ['.config.yml', 'Dangerfile', '.yamllint']

# set the files to watch and warn about if there are
@dependency_files = ['Gemfile, Gemfile.lock']

# determine if any of the files were modified
def did_modify(files_array)
  did_modify_files = false
  files_array.each do |file_name|
    next unless git.modified_files.include?(file_name) || git.deleted_files.include?(file_name)

    did_modify_files = true
    config_files = git.modified_files.select { |path| path.include? file_name }
    message "This PR changes #{github.html_link(config_files)}"
  end

  did_modify_files
end

# Warn when CI/CD related files are changed
warn('Changes to CI/CD files') if did_modify(@ci_files)

# Warn when changing the requirements files
warn('Changes to dependency related files') if did_modify(@dependency_files)

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]"

# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example
not_declared_trivial = !(github.pr_title.include? "#trivial")

# Changelog entries are required for changes to library files.
no_changelog_entry = !git.modified_files.include?("CHANGELOG.md")

# Dont warn about changelog until we decide on our process.
temp_skip_changelog = true

if no_changelog_entry && not_declared_trivial && !temp_skip_changelog
  warn("Any major changes should be reflected in the Changelog.
  Please consider adding a note there and adhere to the
  [Changelog Guidelines](https://keepachangelog.com/en/1.0.0/).")
end

# put labels on PRs, this will autofail all PRs without contributor intervention
# (this is intentional to force someone to look at and categorize each PR before merging)
raise('PR needs labels', sticky: true) if github.pr_labels.empty?
