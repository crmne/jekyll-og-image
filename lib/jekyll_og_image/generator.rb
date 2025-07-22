# frozen_string_literal: true

class JekyllOgImage::Generator < Jekyll::Generator
  safe true

  def generate(site)
    config = JekyllOgImage.config

    config.collections.each do |type|
      process_collection(site, type, config)
    end
  end

  private

  def process_collection(site, type, config)
    Jekyll.logger.info "Jekyll Og Image:", "Processing type: #{type}" if config.verbose?

    items = get_items_for_collection(site, type)
    return if items.empty?

    base_output_dir = File.join(config.output_dir, type)
    absolute_output_dir = File.join(site.config["source"], base_output_dir)
    FileUtils.mkdir_p absolute_output_dir

    items.each do |item|
      if item.respond_to?(:draft?) && item.draft? && config.skip_drafts?
        Jekyll.logger.info "Jekyll Og Image:", "Skipping draft: #{item.data['title']}" if config.verbose?
        next
      end

      fallback_basename = if item.respond_to?(:basename_without_ext)
                            item.basename_without_ext
                            # rubocop:disable Layout/ElseAlignment # Disabled due to RuboCop error in v3.3.0
                          else
                            # rubocop:enable Layout/ElseAlignment
                            File.basename(item.name, File.extname(item.name))
      end

      slug = item.data["slug"] || Jekyll::Utils.slugify(item.data["title"] || fallback_basename)
      image_filename = "#{slug}.png"
      absolute_image_path = File.join(absolute_output_dir, image_filename)
      relative_image_path = File.join("/", base_output_dir, image_filename) # Use leading slash for URL

      if !File.exist?(absolute_image_path) || config.force?
        Jekyll.logger.info "Jekyll Og Image:", "Generating image #{absolute_image_path}" if config.verbose?
        generate_image_for_document(site, item, absolute_image_path, config)
      else
        Jekyll.logger.info "Jekyll Og Image:", "Skipping image generation for #{relative_image_path} as it already exists." if config.verbose?
      end

      item.data["image"] ||= {
        "path" => relative_image_path,
        "width" => JekyllOgImage.config.canvas.width,
        "height" => JekyllOgImage.config.canvas.height,
        "alt" => item.data["title"]
      }
    end
  end

  def get_items_for_collection(site, type)
    case type
    when "posts"
      site.posts.docs
    when "pages"
      site.pages.reject { |page| !page.html? }
    else
      if site.collections.key?(type)
        site.collections[type].docs
      else
        Jekyll.logger.warn "Jekyll Og Image:", "Unknown collection type \"#{type}\" configured. Skipping."
        []
      end
    end
  end

  def generate_image_for_document(site, item, path, base_config)
    config = base_config.merge!(item.data["og_image"] || {})

    return unless config.enabled?

    canvas = generate_canvas(site, config)
    canvas = add_border_bottom(canvas, config) if config.border_bottom
    canvas = add_image(canvas, File.read(File.join(site.config["source"], config.image.path)), config) if config.image.path
    canvas = add_header(canvas, item, config)
    canvas = add_metadata(canvas, item, config)
    canvas = add_domain(canvas, item, config) if config.domain

    canvas.save(path)
  end

  def generate_canvas(site, config)
    background_image = if config.canvas.background_image
      bg_path = File.join(site.config["source"], config.canvas.background_image.gsub(/^\//, ""))
      File.exist?(bg_path) ? File.read(bg_path) : nil
    end

    JekyllOgImage::Element::Canvas.new(JekyllOgImage.config.canvas.width, JekyllOgImage.config.canvas.height,
      background_color: config.canvas.background_color,
      background_image: background_image
    )
  end

  def add_border_bottom(canvas, config)
    canvas.border(config.border_bottom.width,
      position: :bottom,
      fill: config.border_bottom.fill
    )
  end

  def add_image(canvas, image_data, config)
    image_config = config.image
    canvas.image(image_data,
      gravity: image_config.gravity,
      width: image_config.width,
      height: image_config.height,
      radius: image_config.radius
    ) { |_canvas, _text| { x: image_config.position[:x], y: image_config.position[:y] } }
  end

  def add_header(canvas, item, config)
    title = item.data["title"] || "Untitled"
    full_title = "#{config.header.prefix}#{title}#{config.header.suffix}"

    # Calculate available width for header text to avoid overlap with image
    header_width = if config.image.path
      # Canvas width - left margin - right margin - image width - spacing
      # 1200 - 80 - 80 - image_width - 30 (spacing)
      1040 - config.image.width - 30
    else
      1040
    end

    canvas.text(full_title,
      width: header_width,
      color: config.header.color,
      dpi: 400,
      font: config.header.font_family
    ) { |_canvas, _text| { x: 80, y: 100 } }
  end

  def add_metadata(canvas, item, config)
    metadata_parts = []

    config.metadata.fields.each do |field|
      case field
      when "date"
        if item.respond_to?(:date) && item.date
          metadata_parts << item.date.strftime(config.metadata.date_format)
        end
      when "tags"
        if item.data["tags"]&.is_a?(Array) && item.data["tags"].any?
          metadata_parts << item.data["tags"].map { |tag| "##{tag}" }.join(" ")
        end
      else
        # Support custom fields from front matter
        if item.data[field]
          metadata_parts << item.data[field].to_s
        end
      end
    end

    return canvas if metadata_parts.empty?

    metadata_text = metadata_parts.join(config.metadata.separator)

    # Calculate available width based on whether domain is present
    metadata_width = config.domain ? 600 : 1040

    canvas.text(metadata_text,
      gravity: :sw,
      width: metadata_width,
      color: config.content.color,
      dpi: 150,
      font: config.content.font_family
    ) { |_canvas, _text| { x: 80, y: config.margin_bottom } }
  end


  def add_domain(canvas, item, config)
    # Check if any metadata is being displayed
    has_metadata = config.metadata.fields.any? do |field|
      case field
      when "date"
        item.respond_to?(:date) && item.date
      when "tags"
        item.data["tags"]&.is_a?(Array) && item.data["tags"].any?
      else
        item.data[field]
      end
    end

    y_pos = has_metadata ? config.margin_bottom + 50 : config.margin_bottom

    canvas.text(config.domain,
      gravity: :se,
      color: config.content.color,
      dpi: 150,
      font: config.content.font_family
    ) { |_canvas, _text| { x: 80, y: y_pos } }
  end
end
