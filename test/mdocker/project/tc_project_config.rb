require_relative '../../test_helper'

module MDocker
  class ProjectConfigTest < Test::Unit::TestCase

    include MDocker::TestBase

    # noinspection RubyStringKeysInHashInspection
    def test_docker
      assert_images 'docker', [['os', 'debian:jessie', {}], ['tool_2', 'test_tool_2', {'name_2'=>'value_2'}]]
    end

    def test_docker_not_first
      assert_raise(StandardError) {
        assert_images 'docker_not_first', []
      }
    end

    def test_duplicate_image_label
      assert_raise(StandardError) {
        assert_images 'duplicate_image_label', []
      }
    end

    def test_empty
      user_name = Util::user_info[:name]
      assert_images('empty', [['base', 'debian:jessie', {}]], true, user_name)
    end

    # noinspection RubyStringKeysInHashInspection
    def test_skip_user
      assert_images('skip_user',
                    [['user', 'user', {}], ['os', 'debian:jessie', {}], ['tool_1', 'test_tool_1', {'name_1'=>'value_1'}], ['tool_2', 'test_tool_2', {'name_2'=>'value_2'}]],
                    false)
    end

    def test_missing_image
      assert_raise(IOError) {
        assert_images 'missing_image', []
      }
    end

    # noinspection RubyStringKeysInHashInspection
    def test_project
      assert_images 'project', [['tool_1', 'test_tool_1', {'name_1'=>'value_1'}], ['tool_2', 'test_tool_2', {'name_2'=>'value_2'}]]
    end

    def test_wrong_image
      assert_raise(StandardError) {
        assert_images 'wrong_image', []
      }
    end

    def test_no_images
      assert_images 'no_images', [['base', 'debian:jessie', {}]]
    end

    def test_tags
      assert_images 'tags',[['tag', 'tag', {}], ['os', 'debian:jessie', {}], ['base_tag', 'base_tag', {}], ['base_tag2', 'base_tag2', {}]]
    end

    def assert_images(project_name, expected, include_user=true, user_name='test_user')
      if include_user
        user_contents = File.read(File.join(Util::datadir, 'user'))
        user_args = Util::stringify_keys(Util::user_info)
        user_args['name'] = user_name
        user_args['group'] = user_name
        expected << ['user', user_contents, user_args]
      end

      with_project_config(name: project_name) do |_, config|
        assert_equal expected, (config.images { |label, object, args| [label, object.contents, args] })
      end
    end

  end
end