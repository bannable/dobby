# frozen_string_literal: true

module Debsecan
  module Formatter
    # TODO: Document me.
    class FormatterSet < Array
      BUILTIN_FORMATTERS = {
        'simple' => SimpleFormatter,
        'json' => JSONFormatter
      }.freeze

      FORMATTER_APIS = %i[started finished file_started].freeze

      FORMATTER_APIS.each do |method_name|
        define_method(method_name) do |*args|
          each { |f| f.send(method_name, *args) }
        end
      end

      def initialize(options = {})
        @options = options
      end

      def file_finished(file, results)
        each { |f| f.file_finished(file, results) }
        results
      end

      def add_formatter(type, output_path = nil)
        if output_path
          dir_path = File.dirname(output_path)
          FileUtils.mkdir_p(dir_path) unless File.exist?(dir_path)
          output = File.open(output_path, 'w')
        else
          output = $stdout
        end

        self << formatter_class(type).new(output, @options)
      end

      def close_output_files
        each do |formatter|
          formatter.output.close if formatter.output.is_a?(File)
        end
      end

      private

      def formatter_class(formatter_type)
        case formatter_type
        when Class
          formatter_type
        when /\A[A-Z]/
          custom_formatter_class(formatter_type)
        else
          builtin_formatter_class(formatter_type)
        end
      end

      def builtin_formatter_class(specified_key)
        matching_keys = BUILTIN_FORMATTERS.keys.select do |key|
          key.start_with?(specified_key)
        end

        raise %(No formatter for "#{specified_key}") if matching_keys.empty?

        if matching_keys.size > 1
          raise %(Cannot determine formatter for "#{specified_key}")
        end

        BUILTIN_FORMATTERS[matching_keys.first]
      end

      def custom_formatter_class(specified_class_name)
        constant_names = specified_class_name.split('::')
        constant_names.shift if constant_names.first.empty?
        constant_names.reduce(Object) do |namespace, constant_name|
          namespace.const_get(constant_name, false)
        end
      end
    end
  end
end
