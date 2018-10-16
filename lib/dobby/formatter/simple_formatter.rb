# frozen_string_literal: true

module Dobby
  module Formatter
    # Outputs simple text, possibly colored
    class SimpleFormatter < AbstractFormatter
      include Colorizable

      def file_finished(_file, results)
        return if results.empty?

        each_completed_result(results)
      end

      private

      def each_completed_result(results)
        results.each do |package, defects|
          output.puts
          print_package(package)
          print_each_defect(defects)
        end
      end

      def print_package(package)
        output.puts(package)
      end

      def print_each_defect(defects)
        defects.sort_by(&:severity).each { |d| print_defect(d) }
      end

      def print_defect(defect)
        severity = colored_severity(defect.severity)
        output.printf("\t%-25s %-10s\n", defect.identifier, severity)
      end

      def colored_severity(severity)
        case severity
        when Severity::Negligible, Severity::Low
          green(severity)
        when Severity::Medium
          yellow(severity)
        when Severity::High
          magenta(severity)
        when Severity::Critical
          red(severity)
        else
          white(severity)
        end
      end
    end
  end
end
