require 'awestruct/astruct'

module Awestruct
  module Extensions
    class Downloads

      @@index_path = "/downloads/index.html"
      @@output_path_prefix = "/downloads/"
      @@layout_path = "download_single_version.html.haml"
      @@build_types = {:stable => [".GA", ".Final"], :development=>[".Alpha", ".Beta", ".CR"], :nightly=>["nightly", "Nightly"]}

      def initialize()
      end

      # generates synthetic pages for all downloadable versions of JBDS and JBT (stable, dev, nightly and older)
      def execute(site)
        $LOG.debug "*** Executing downloads extension..." if $LOG.debug?
        # making these labels available in layouts, too.
        site.labels = {:stable=>"Stable", :development=>"Development", :nightly=>"Nightly"}
        @site = site
        @site.download_pages = Hash.new
        @site.download_perma_links = Hash.new #permalinks per active eclipse stream.
        @site.all_versions_download_pages = Hash.new
        @site.latest_stable_builds_download_pages = Hash.new
        # generate a page for each dev/nightly/stable build per product until a version with a stable build is found 
        # (thus, skipping older product streams),
        # then 1 page for all stable builds (only) per product
        for product in [:devstudio, :devstudio_is, :jbt_core, :jbt_is]
          @site.download_pages[product] = Hash.new
          @site.download_perma_links[product] = Hash.new #permalinks per active eclipse stream.
          if site.products[product].nil? then
            next
          end
          # each product (DevStudio, etc.) is splitted on many Eclipse versions (Luna, etc)
          site.products[product][:streams].each do |eclipse_id, eclipse_stream|
            eclipse_version = site.products[:eclipse][eclipse_id]
            #permalinks per active eclipse stream.
            @site.download_perma_links[product][eclipse_id] = Hash.new if eclipse_version.active
            @site.download_pages[product][eclipse_id] = Array.new
            #permalinks for "stable.html", "development.html", etc. 
            # for each Eclipse versions can have many product builds, each one with build info
            eclipse_stream.each do |build_version, build_info|
              build_type = guess_build_type(build_version) 
              build_info.name = site.products[product].name
              build_info.product = product
              build_info.version = build_version
              build_info.eclipse_version = eclipse_version
              build_info.build_type = build_type
              build_info.active = eclipse_version.active
              build_info.blog_announcement_url = (defined? build_version.blog_announcement_url) ? build_version.blog_announcement_url : nil
              build_info.release_notes_url = (defined? build_version.release_notes_url) ? build_version.release_notes_url : nil
              build_info.whatsnew_url = (defined? build_version.whatsnew_url) ? build_version.whatsnew_url : nil
              build_info.update_site_url = (defined? build_version.update_site_url) ? build_version.update_site_url : nil              
              build_info.marketplace_install_url = (defined? build_version.marketplace_install_url) ? build_version.marketplace_install_url : nil
              # link to download page: selecting the first module's N&N for the closest version if none match (ex: .CR1 for .Final)
              build_info.whatsnew_output_path = nil?
              if build_type == :stable || build_type == :development
                whatsnew_page = get_whatsnew_page(build_info.product, build_info.version)
                build_info.whatsnew_output_path = whatsnew_page.output_path unless whatsnew_page.nil?
              end
              # finally, build regular download page
              download_page = generate_single_version_download_page(product, eclipse_version, 
                    build_version.to_s, build_info, build_version)
              if eclipse_version.active && @site.latest_stable_builds_download_pages[product].nil? && 
                  build_type == :stable then
                @site.latest_stable_builds_download_pages[product] = download_page
              end
                    
              @site.pages << download_page 
              @site.download_pages[product][eclipse_id] << download_page 
            end
          end
          #puts "*** Download permalinks for " + product.to_s + ": " + @site.download_perma_links[product].to_s
        end
        $LOG.debug "*** Done with downloads extension." if $LOG.debug?
      end
      
      def get_whatsnew_page(product_name, product_version)
        #puts " looking for N&N for #{product_name} version #{product_version}..."
        whatsnew_aggregated_page = @site.whatsnew_pages[product_version]
        unless whatsnew_aggregated_page.nil?
          #puts " whatsnew for #{product_name} #{product_version} will link to #{whatsnew_aggregated_page.output_path}"
          whatsnew_aggregated_page
        end
        #puts "  no whatsnew for #{product_name} #{product_version}"
        nil
      end

      def generate_single_version_download_page(product, eclipse_version, page_path_fragment, build_info, build_version)
        page_title ||= @site.products[product].name + " " + build_version.to_s
        product_path_fragment = @site.products[product].url_path_fragment
        path = @@output_path_prefix + product_path_fragment + "/" + eclipse_version.url_path_fragment + "/" + page_path_fragment + ".html"
        page = generate_download_page(path)
        page.title = page_title
        page.build_info = build_info
        page.product = product
        page.eclipse_version = eclipse_version
        #puts "  generated download page at '" + page.output_path + "' with title '" + page.title + "'"
        page
      end

      def generate_download_page(path)
        page = find_layout_page(@@layout_path)
        page.output_path = File.join(path)
        @site.pages << page
        return page
      end
      
      def guess_build_type(build_version)
        @@build_types.each do |type, suffixes| 
          unless suffixes.select{|suffix| build_version.include? suffix}.first.nil?
            return type
          end
        end
        puts "Unable to determine build type for " + build_version + ", assuming :development, then.."
        return :development
      end
      
      def find_blog_announcement_path(blog_announcement_page_name)
        unless blog_announcement_page_name.nil? || blog_announcement_page_name.empty?
          #puts "Looking for post page matching '" + blog_announcement_page_name.to_s + "'"
          @site.posts.each do |post|
            #puts " " + post.simple_name
            if post.simple_name.eql? blog_announcement_page_name
              return post.output_path
            end
          end
          puts "Unable to find page for blog " + blog_announcement_page_name.to_s
        end
        return nil
      end
      
      def find_layout_page(simple_path)
        path_glob = File.join( @site.config.layouts_dir, simple_path)
        candidates = Dir[ path_glob ]
        return nil if candidates.empty?
        throw Exception.new( "too many choices for #{simple_path}" ) if candidates.size != 1
        @site.engine.load_page( candidates[0] )
      end
    end

    
  end
  
end
