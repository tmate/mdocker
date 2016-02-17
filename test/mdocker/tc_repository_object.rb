require_relative '../test_helper'

module MDocker
  class RepositoryObjectTest < TestBase

    def test_object_load
      @default_fixture.copy { |fixture|
        repository = create_default_repository(fixture)
        [
          fixture.expand_path('file_roaming'),
          fixture.expand_path('directory_roaming'),
          'file',
          'file_project',
          'file_global',
          'directory',
          'directory_project',
          'directory_global',
        ].each { |location|
          obj = repository.get_object(location)

          assert_not_nil obj
          assert_equal false, obj.has_contents?
          assert_equal true, obj.outdated?

          updated = obj.fetch

          assert_equal true, updated

          assert_equal false, obj.outdated?
          assert_equal true, obj.has_contents?

          updated = obj.fetch
          assert_equal false, updated

          File.write(obj.origin, File.read(obj.origin) + ' modified')

          assert_equal true, obj.has_contents?
          assert_equal true, obj.outdated?

          updated = obj.fetch

          assert_equal true, updated

          assert_equal false, obj.outdated?
          assert_equal true, obj.has_contents?
        }

      }
    end

    def test_git_object_load
      fixture = @default_fixture.copy
      repository = create_default_repository(fixture)
      obj = repository.get_object('file://' + fixture.expand_path('repository.git') + '|master|file')

      assert_not_nil obj
      assert_equal false, obj.has_contents?
      assert_equal true, obj.outdated?

      updated = obj.fetch

      assert_equal true, updated
      assert_equal true, obj.has_contents?
      assert_equal 'file', obj.contents
    end

    def test_git_object_load_fail
      fixture = @default_fixture.copy
      repository = create_default_repository(fixture)
      obj1 = repository.get_object('file://' + fixture.expand_path('missing.git') + '|master|file')
      obj2 = repository.get_object('file://' + fixture.expand_path('repository.git') + '|master|missing')
      obj3 = repository.get_object('file://' + fixture.expand_path('repository.git') + '|missing|file')

      [obj1, obj2, obj3].each do |obj|
        assert_not_nil obj
        assert_equal false, obj.has_contents?
        assert_equal true, obj.outdated?

        begin
          obj.fetch
          assert_fail_assertion
        rescue
          #
        end
      end

    end
  end
end