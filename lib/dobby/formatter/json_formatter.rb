# frozen_string_literal: true

module Dobby
  module Formatter
    # Outputs results as JSON
    class JSONFormatter < AbstractFormatter
      def started(_target_files)
        @results = {}
      end

      def file_started(file)
        @results[file] = []
      end

      def file_finished(file, results)
        return if results.empty?

        @results[file] = each_completed_result(results)
      end

      def finished(_files)
        output.puts(Oj.dump(@results, mode: :strict))
      end

      private

      def each_completed_result(results)
        results.map do |package, defects|
          {
            package: package.name,
            version: package.version,
            defects: serialize_each_defect(defects)
          }
        end
      end

      def serialize_each_defect(defects)
        defects.sort_by(&:severity).map(&:to_hash)
      end
    end
  end
end
