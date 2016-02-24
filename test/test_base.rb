module MDocker
  module TestBase

    DEFAULT_FIXTURE_NAME = 'default'
    DEFAULT_FILE_NAME = 'Dockerfile'
    DEFAULT_REPOSITORY_PATHS = %w(project/.mdocker/dockerfiles .mdocker/dockerfiles)
    DEFAULT_LOCK_PATH = '.mdocker/locks'
    DEFAULT_TMP_LOCATION = 'project/.mdocker/tmp'

    def with_repository(fixture_name=DEFAULT_FIXTURE_NAME, file_name=DEFAULT_FILE_NAME, repository_paths=DEFAULT_REPOSITORY_PATHS, locks_path=DEFAULT_LOCK_PATH, git_tmp_path=DEFAULT_TMP_LOCATION)
      with_fixture(fixture_name) do |fixture|
        providers = [
            GitRepositoryProvider.new(file_name, fixture.expand_path(git_tmp_path)),
            AbsolutePathProvider.new(file_name),
            PathProvider.new(file_name, fixture.expand_paths(repository_paths)),
        ]
        expensive_provider = providers.max_by { |provider| provider.update_price }
        repository = MDocker::Repository.new(fixture.expand_path(locks_path), providers, expensive_provider.update_price)
        yield fixture, repository
      end
    end

    def with_fixture(fixture_name=DEFAULT_FIXTURE_NAME)
      Fixture.create(fixture_name).copy do |fixture|
        yield fixture
      end
    end

  end
end