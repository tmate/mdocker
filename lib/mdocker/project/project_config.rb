module MDocker
  class ProjectConfig

    def initialize(config, repository)
      @config = config
      @repository = repository

      #
      # process config:
      #
      # - merge in user defaults into default flavor
      # - merge in project flavors, concatenate images!
      #
      #   so images go as that:
      #   images: [super flavor level] // e.g. debian
      #   images [flavor level] // e.g. java8, maven
      #   images: [project level] // e.g atlas-sdk
      #   what about multiple inheritance?
      #
      #   and support special boolean label, that stops inheritance:
      #   images:
      #   - inherit: false
      #     start processing images after the last :inherit label
      #
      # - append user image, unless explicitly disabled in container
      #
    end

    def name
      @config.get('project.name', @config.get('default.project.name', 'mdocker'))
    end

    def images(update_threshold=0)
      load_images.map do |source|
        image = source[:image]
        label = image[:label]
        location = image[:location]
        object = image[:object]
        args = image[:args]

        object.fetch if object.outdated?(update_threshold)

        raise IOError.new "failed to fetch image '#{label}' from '#{location}'" if object.contents.nil?

        yield label, object, args
      end
    end

    def load_images
      images = resolve_images @config.get('image', [])
      images = empty_images?(images) ? resolve_images(@config.get('default.image', [])) + images : images
      raise StandardError.new 'no image defined' if empty_images?(images)
      (images << create_user_image('user')) unless images.find { |r| r[:label] == 'user' }
      images
    end

    def resolve_images(images)
      raise StandardError.new("value of Array type is expected for 'image' property") unless Array === images
      images.inject([]) do |resolved, source|
        image = resolve_image source
        next resolved if image.nil?

        raise StandardError.new "duplicate image label '#{image[:label]}'" if resolved.find { |r| r[:label] == image[:label] }
        if image[:location][:docker] && !empty_images?(resolved)
          raise StandardError.new("image '#{image[:label]}' of type 'docker' may only be the first image in the sequence")
        end

        resolved << {image: image, label: image[:label]}
      end
    end

    def resolve_image(source)
      source = { source => nil } if String === source
      label, location = source.first
      return nil if label.nil?

      raise StandardError.new "value of String or Hash type is expected for #{label} image" unless (location.nil? || Hash === location || String === location)

      location = {tag: label} if location.nil? || (String === location && location.empty?)
      location = {gem: location} if String === location
      location = MDocker::Util::symbolize_keys(location)

      image = {label: label, location: location, args: (source['args'] || {})}
      image[:object] = @repository.object(image[:location])
      raise StandardError.new "unrecognized image specification for '#{label}': #{location}" unless image[:object]
      image
    end

    def empty_images?(images)
      images.empty? || (images.find { |r| r[:image][:location][:tag].nil? } == nil)
    end

    # noinspection RubyStringKeysInHashInspection
    def create_user_image(image_name)
      user_info = @config.merge('default.container.user', 'container.user')
      location = {gem: 'user'}
      {image: resolve_image({
                                image_name => location,
                                'args' => Util::stringify_keys(user_info)
                            }), label: image_name}
    end

  end
end