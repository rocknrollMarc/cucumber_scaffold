module CucumberScaffold
  class FeatureGenerator < Rails::Generators::NamedBase

    INDENT = "        "
    LINE_BREAK_WITH_INDENT = "\n#{INDENT}"
    LINE_BREAK_WITH_INDENT_COMMENTED = "\n#{INDENT}# "

    argument :model_name, :type => :string

    source_root File.expand_path('../templates', __FILE__)

    def initialize(args, *options)
      # copied setup from
      # http://apidock.com/rails/Rails/Generators/NamedBase/new/class
      args[0] = args[0].dup if args[0].is_a?(String) && args[0].frozen?
      super
      assign_names!(self.name)
      parse_attributes! if respond_to?(:attributes)
      args.shift
      @args = args
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
      when /edit page for that #{singular}/
        edit_#{singular}_path(@#{singular})
      when /page for that #{singular}/
        raise 'no #{singular}' unless @#{singular}
        #{singular}_path(@#{singular})
      when /edit page for the (\\d+)(?:st|nd|rd|th) #{singular}/
        raise 'no #{plural}' unless @#{plural}
        nth_#{singular} = @#{plural}[$1.to_i - 1]
        edit_#{singular}_path(nth_#{singular})
      when /page for the (\\d+)(?:st|nd|rd|th) #{singular}/
        raise 'no #{plural}' unless @#{plural}
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
      options[:nifty].present?
    end

    def singular
      name.underscore.downcase
    end

    def plural
      singular.pluralize
    end

    def singular_title
      singular.titleize
    end

    def plural_title
      plural.titleize
    end

    def activerecord_table_header_row
      make_row(attribute_names)
    end

    def html_table_header_row
      make_row(attribute_names.map(&:titleize))
    end

    def attribute_names
      @attributes.collect {|a| a.first[0]}
    end

    def html_single_resource(updated=nil, commented=nil)
      lines = []
      @attributes.each do |pair|
        attribute_name = pair.first[0]
        attribute_value = pair.first[1]
        lines << "| #{attribute_name.titleize}: | #{default_value(attribute_name, attribute_value, updated)} |"
      end
      lines.join(commented ? LINE_BREAK_WITH_INDENT_COMMENTED : LINE_BREAK_WITH_INDENT)
    end

    def form_single_resource_commented
      form_single_resource(false, true)
    end

    def html_single_resource_commented
      html_single_resource(false, true)
    end

    def form_single_resource(updated=nil, commented=nil)
      lines = []
      @attributes.each do |pair|
        attribute_name = pair.first[0]
        attribute_value = pair.first[1]
        lines << "| #{attribute_name.titleize} | #{default_value(attribute_name, attribute_value, updated)} |"
      end
      result = lines.join(commented ? LINE_BREAK_WITH_INDENT_COMMENTED : LINE_BREAK_WITH_INDENT)
    end

    def activerecord_single_resource(updated=nil)
      lines = []
      @attributes.each do |pair|
        attribute_name = pair.first[0]
        attribute_value = pair.first[1]
        lines << "| #{attribute_name} | #{default_value(attribute_name, attribute_value, updated)} |"
      end
      lines.join(LINE_BREAK_WITH_INDENT)
    end

    def html_resources
      [html_table_header_row,
        html_table_row(1),
        html_table_row(2),
        html_table_row(3)].join(LINE_BREAK_WITH_INDENT)
    end

    def activerecord_resources
      [activerecord_table_header_row,
         activerecord_table_row(1),
         activerecord_table_row(2),
         activerecord_table_row(3)].join(LINE_BREAK_WITH_INDENT)
    end

    def activerecord_single_resource_updated
      activerecord_single_resource(true)
    end

    def form_single_resource_updated
      form_single_resource(true)
    end

    def html_single_resource_updated
      html_single_resource(true)
    end

    def default_value(attribute_name, attribute_type, updated=false, index=1)
      # TODO use an options hash instead of all these arguments
      if ['string', 'text'].include?(attribute_type)
        result = "#{attribute_name} #{index}"
        result += ' updated' if updated
      elsif attribute_type == 'integer'
        result = 10 + index
        result = -result if updated
      else
        raise "Cannot create default value for attribute type '#{attribute_type}'"
      end
      result
    end

    def activerecord_table_row(n)
      data = []
      @attributes.each do |attribute|
        attribute_name = attribute.first[0]
        attribute_type = attribute.first[1]
        data << default_value(attribute_name, attribute_type, false, n)
      end
      make_row(data)
    end

    def html_table_row(n)
      activerecord_table_row(n)
    end

    def tags(tags)
      tags
    end
  
    def make_row(data)
      "| #{data.join(' | ')} |"
    end
  
  end
end