module CucumberScaffold
  class FeatureGenerator < Rails::Generators::NamedBase

    INDENT = "        "
    LINE_BREAK_WITH_INDENT = "\n#{INDENT}"
    LINE_BREAK_WITH_INDENT_COMMENTED = "\n#{INDENT}# "

    argument :model_name, :type => :string

    source_root File.expand_path('../templates', __FILE__)

    def initialize(args, *options)
      super
      args.shift
      @args = args
      # seems to be a conflict if I call this @options
      @x_options = options
    end

    def do_it
      @attributes = []
      @args.each do |param_pair|
        name, type = param_pair.split(':')
        @attributes << { name => type }
      end

      template('feature.feature', "features/manage_#{plural}.feature")
      template('steps.rb', "features/step_definitions/#{singular}_steps.rb")

      extra_paths = <<EOF
      when /edit page for that #{singular.humanize.downcase}/
        edit_#{singular}_path(@#{singular})
      when /page for that #{singular.humanize.downcase}/
        raise 'no #{singular.humanize.downcase}' unless @#{singular}
        #{singular}_path(@#{singular})
      when /edit page for the (\\d+)(?:st|nd|rd|th) #{singular.humanize.downcase}/
        raise 'no #{plural.humanize.downcase}' unless @#{plural}
        nth_#{singular} = @#{plural}[$1.to_i - 1]
        edit_#{singular}_path(nth_#{singular})
      when /page for the (\\d+)(?:st|nd|rd|th) #{singular.humanize.downcase}/
        raise 'no #{plural.humanize.downcase}' unless @#{plural}
        nth_#{singular} = @#{plural}[$1.to_i - 1]
        #{singular}_path(nth_#{singular})
EOF

      gsub_file 'features/support/paths.rb', /'\/'/mi do |match|
        "#{match}\n" + extra_paths
      end

    end

    private

      def generated_by
        '# Generated by cucumber_scaffold - http://github.com/andyw8/cucumber_scaffold'
      end

      def nifty?
        # there's probably a better way to do this
        @x_options.include?(["--nifty"])
      end

      def singular
        name.underscore.downcase
      end

      def plural
        singular.pluralize
      end

      def singular_title
        singular.humanize
      end

      def plural_title
        plural.humanize
      end

      def activerecord_table_header_row
        make_row(attribute_names)
      end

      def html_table_header_row
        make_row(attribute_names.map(&:humanize))
      end

      def attribute_names
        @attributes.collect {|a| a.first[0].gsub('_', ' ')}
      end

      def html_single_resource(options={})
        lines = []
        @attributes.each do |pair|
          attribute_name = pair.first[0]
          attribute_type = pair.first[1]
          default_value = default_value(:attribute_name => attribute_name, :attribute_type => attribute_type, :updated => options[:updated])
          
          lines << "| #{attribute_name.humanize}: | #{default_value} |"
        end
        lines.join(options[:commented] ? LINE_BREAK_WITH_INDENT_COMMENTED : LINE_BREAK_WITH_INDENT)
      end

      def form_single_resource_commented
        form_single_resource(:commented => true)
      end

      def html_single_resource_commented
        html_single_resource(:commented => true)
      end

      def form_single_resource(options = {})
        lines = []
        @attributes.each do |pair|
          attribute_name = pair.first[0]
          attribute_type = pair.first[1]
          lines << "| #{attribute_name.humanize} | #{default_value(:attribute_name => attribute_name, :attribute_type => attribute_type, :updated => options[:updated], :form => true)} |"
        end
        result = lines.join(options[:commented] ? LINE_BREAK_WITH_INDENT_COMMENTED : LINE_BREAK_WITH_INDENT)
      end

      def activerecord_single_resource(options={})
        lines = []
        @attributes.each do |pair|
          attribute_name = pair.first[0]
          attribute_type = pair.first[1]
          lines << "| #{attribute_name} | #{default_value(:attribute_name => attribute_name, :attribute_type => attribute_type, :updated =>options[:updated])} |"
        end
        lines.join(LINE_BREAK_WITH_INDENT)
      end

      def html_resources
        [html_table_header_row,
          html_table_row(:index => 1),
          html_table_row(:index => 2),
          html_table_row(:index => 3)].join(LINE_BREAK_WITH_INDENT)
      end

      def activerecord_resources
        [activerecord_table_header_row,
           activerecord_table_row(:index => 1),
           activerecord_table_row(:index => 2),
           activerecord_table_row(:index => 3)].join(LINE_BREAK_WITH_INDENT)
      end

      def activerecord_single_resource_updated
        activerecord_single_resource(:updated => true)
      end

      def form_single_resource_updated
        form_single_resource(:updated => true)
      end

      def html_single_resource_updated
        html_single_resource(:updated => true)
      end

      def default_value(options={})
        options[:index] ||= 10
        
        if ['string', 'text'].include?(options[:attribute_type])
          result = "#{options[:attribute_name].humanize.downcase} #{options[:index]}"
          result += ' updated' if options[:updated]
        elsif options[:attribute_type] == 'integer'
          result = 10 + options[:index]
          result = -result if options[:updated]
        elsif options[:attribute_type] == 'decimal'
          result = 10.2 + index
          result = -result if options[:updated]
        elsif ptions[:attribute_type] == 'references'
          model = options[:attribute_name].camelize.constantize
          result = model.first
          result = model.last if updated
        elsif options[:attribute_type] == 'boolean'
          if options[:form]
            result = '[x]'
            result = '[ ]' if options[:updated]
          else
            result = true
            result = false if options[:updated]
          end
        else
          raise "Cannot create default value for attribute type '#{options[:attribute_type]}'"
        end
        result
      end

      def activerecord_table_row(options)
        data = []
        @attributes.each do |attribute|
          attribute_name = attribute.first[0]
          attribute_type = attribute.first[1]
          data << default_value(:attribute_name => attribute_name, :attribute_type => attribute_type, :index => options[:index])
        end
        make_row(data)
      end

      def html_table_row(options)
        activerecord_table_row(options)
      end

      def tags(tags)
        tags
      end

      def make_row(data)
        "| #{data.join(' | ')} |"
      end

  end
end

