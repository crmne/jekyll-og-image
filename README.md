# Jekyll OG Image

A Jekyll plugin to automatically generate open graph images for posts.

[![Gem Version](https://badge.fury.io/rb/jekyll-og-image.svg)](https://badge.fury.io/rb/jekyll-og-image)
[![Lint](https://github.com/igor-alexandrov/jekyll-og-image/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/igor-alexandrov/jekyll-og-image/actions/workflows/lint.yml)
[![Tests](https://github.com/igor-alexandrov/jekyll-og-image/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/igor-alexandrov/jekyll-og-image/actions/workflows/tests.yml)

## Installation

Add this line to your site's Gemfile:

```ruby
  gem 'jekyll-og-image'
```

And then add this line to your site's `_config.yml`:

```yaml
plugins:
  - jekyll-seo-tag
  - jekyll-og-image
```

This plugin requires `libvips` to be installed. If you are using GitHub Pages to host your Jekyll site, don't forget to install `libvips` before running `jekyll build`. See the example below.

``` yaml
jobs:
  build:
    needs:
      - lint
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: .ruby-version
          bundler-cache: true

      - name: Set Node.js 20.x
        uses: actions/setup-node@v3
        with:
          node-version: 20.x

      - name: Run install
        uses: borales/actions-yarn@v4
        with:
          cmd: install

      - name: Update apt
        env:
          DEBIAN_FRONTEND: noninteractive
        run: sudo apt-get update -qq

      - name: Install libvips
        env:
          DEBIAN_FRONTEND: noninteractive
        run: sudo apt-get install --fix-missing libvips

      - name: Setup Pages
        id: pages
        uses: actions/configure-pages@v5

      - name: Build with Jekyll
        run: ./bin/jekyll build --baseurl "${{ steps.pages.outputs.base_path }}"
        env:
          JEKYLL_ENV: production

      - name: Upload artifact
        # Automatically uploads an artifact from the './_site' directory by default
        uses: actions/upload-pages-artifact@v3

```

## Usage

Jekyll OG Image works together with [jekyll-seo-tag](https://github.com/jekyll/jekyll-seo-tag) plugin. It automatically generates open graph images for posts and inserts them into the posts metadata.

## Configuration

The plugin can be configured in the `_config.yml` file or in the post's front matter.

The following configuration options are available:

* `collections` - An array specifying which types of collections to generate images for. Supports `"posts"`, `"pages"`, and the names of any custom collections. Default: `["posts"]`

* `output_dir` – The directory where the generated images will be saved. Images will be placed in subdirectories named after their collection type (e.g., `assets/images/og/posts`, `assets/images/og/pages`). Default: `assets/images/og`

* `force` – If set to `true`, the plugin will generate an image for every document, even if the document already has an image. Default: `false`
* `verbose`  – If set to `true`, the plugin will output additional information about the image generation process. Default: `false`

* `skip_drafts` – If set to `true`, the plugin will skip post drafts when generating images. Default: `true`

* `canvas` – The canvas configuration options:
  * `background_color` – The background color of the canvas. Default: `#FFFFFF`
  * `background_image` – The background image of the canvas. Default: `nil`
  * `width` – The width of the generated image in pixels. Default: `1200`
  * `height` – The height of the generated image in pixels. Default: `600`

* `header` – The header configuration options:
  * `font_family` – The font family of the header text. Default: `Helvetica, Bold`
  * `color` – The color of the header text. Default: `#2f313d`
  * `prefix` – Text to prepend to the title. Default: `""`
  * `suffix` – Text to append to the title. Default: `""`

* `content` – The content configuration options:
  * `font_family` – The font family of the content text. Default: `Helvetica, Regular`
  * `color` – The color of the content text. Default: `#535358`

* `border_bottom` – The border bottom configuration options:
  * `width` – The width of the border bottom. Default: `20`
  * `fill` – The array of colors to fill the border bottom. Default: `["#000000"]`

* `domain` – The domain name to use in the image. Default: `nil`

* `image` – Logo/image configuration options. Can be a string (legacy format) or an object with the following options:
  * `path` – Path to the image file. **Note: Use JPEG format for best compatibility. PNG images with transparency may not render correctly.** Default: `nil`
  * `width` – The width of the logo in pixels. Default: `150`
  * `height` – The height of the logo in pixels. Default: `150`
  * `radius` – The radius for rounded corners on the logo. Default: `50`
  * `position` – The position of the logo as `{x, y}` coordinates. Default: `{x: 80, y: 100}`
  * `gravity` – The gravity anchor for logo positioning (nw, n, ne, w, e, sw, s, se). Default: `ne`

* `metadata` – The metadata configuration options:
  * `fields` – Array of metadata fields to display. Available options: `"date"`, `"tags"`, or any custom front matter field. Default: `["date", "tags"]`
  * `separator` – Text to separate multiple metadata fields. Default: `" • "`
  * `date_format` – Date format string for the date field. Default: `"%B %d, %Y"`

## Examples

Configuration can be defined on the site level or on the post level.

For a side wide level configuration, edit your `_config.yml`, for a post level configuration, edit the post's front matter.

### Single Color

```yaml
# _config.yml
og_image:
  collections: ["posts", "pages"]
  output_dir: "assets/images/og"
  domain: "igor.works"
  border_bottom:
    width: 20
    fill:
      - "#4285F4"
```

![Example 2](examples/2.png)

### Multiple Colors

```yaml
# _config.yml
og_image:
  output_dir: "assets/images/og"
  image: "/assets/images/igor.jpeg"
  domain: "igor.works"
  border_bottom:
    width: 20
    fill:
      - "#820C02"
      - "#A91401"
      - "#D51F06"
      - "#DE3F24"
      - "#EDA895"
```

![Example 1](examples/1.png)

### Background Color and Text Color

```yaml
# _config.yml
og_image:
  output_dir: "/assets/og"
  image: "/assets/images/igor.jpeg"
  canvas:
    background_color: "#F9E065"
  header:
    font_family: "Roboto, Bold"
    color: "#333333"
  content:
    font_family: "Roboto, Regular"
    color: "#333333"
  force: false
  domain: "igor.works"
  border_bottom:
    width: 50
    fill:
      - "#002B7F"
      - "#FCD116"
      - "#CE1126"
```

![Example 3](examples/3.png)

### Background Image

```yaml
# _config.yml
og_image:
  output_dir: "/assets/og"
  image: "/assets/images/igor.jpeg"
  header:
    font_family: "Roboto, Bold"
    color: "#333333"
  content:
    font_family: "Roboto, Bold"
    color: "#333333"
  force: false
  domain: "igor.works"

# _posts/2024-02-15-traefik-tunning-for-rails-applications-part-1.md
---
title: Traefik Tuning for Rails Applications (part 1)
layout: post
tags:
  - Rails
  - Traefik
  - Kamal
og_image:
  canvas:
    background_image: "/assets/images/bc_3.jpg"
```

![Example 4](examples/4.png)

### Custom Metadata and Logo Size

```yaml
# _config.yml
og_image:
  domain: "igor.works"
  image:
    path: "/assets/images/logo.png"
    width: 100
    height: 100
    radius: 20
    position:
      x: 60
      y: 60
  header:
    prefix: "📖 "
    suffix: " - My Blog"
  metadata:
    fields: ["author", "date", "reading_time"]
    separator: " | "
    date_format: "%d %B %Y"
```

This configuration:
- Adjusts the logo size to 100x100px with less rounded corners
- Adds a book emoji prefix and " - My Blog" suffix to titles
- Shows author, date, and reading_time in the metadata section
- Uses a pipe separator between metadata fields
- Formats dates as "15 February 2024"


## Contributing

* Fork it (https://github.com/igor-alexandrov/jekyll-og-image)
* Create your feature branch (`git checkout -b my-new-feature`)
* Commit your changes (`git commit -am 'Add some feature'`)
* Push to the branch (`git push origin my-new-feature`)
* Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
