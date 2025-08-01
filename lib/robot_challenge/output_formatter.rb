# frozen_string_literal: true

module RobotChallenge
  # Helper module for common output formatter functionality
  module OutputFormatterHelpers
    def robot_data(robot)
      {
        position: {
          x: robot.position.x,
          y: robot.position.y
        },
        direction: robot.direction.name,
        formatted: robot.report
      }
    end

    def command_descriptions
      Constants::COMMAND_DESCRIPTIONS
    end

    def table_data(table)
      {
        width: table.width,
        height: table.height
      }
    end
  end

  # Abstract base class for output formatters
  class OutputFormatter
    include OutputFormatterHelpers

    def format_report(robot)
      raise NotImplementedError, "#{self.class} must implement #format_report"
    end

    def format_error(message, error_type = :general_error)
      raise NotImplementedError, "#{self.class} must implement #format_error"
    end

    def format_success(message = nil)
      raise NotImplementedError, "#{self.class} must implement #format_success"
    end

    def format_welcome_message(table, valid_directions)
      raise NotImplementedError, "#{self.class} must implement #format_welcome_message"
    end

    def format_goodbye_message
      raise NotImplementedError, "#{self.class} must implement #format_goodbye_message"
    end
  end

  # Default text formatter (current behavior)
  class TextOutputFormatter < OutputFormatter
    def format_report(robot)
      robot.report
    end

    def format_error(_message, _error_type = :general_error)
      # Silently ignore errors as per requirements
      nil
    end

    def format_success(_message = nil)
      # No output for success as per requirements
      nil
    end

    def format_welcome_message(table, valid_directions)
      commands = command_descriptions

      <<~WELCOME
        #{Constants::APPLICATION_NAME}
        ========================

        Commands:
          #{commands[:place]}
          #{commands[:move]}
          #{commands[:left]}
          #{commands[:right]}
          #{commands[:report]}

        Table size: #{table}
        Valid directions: #{valid_directions.join(', ')}

      WELCOME
    end

    def format_goodbye_message
      "\n#{Constants::SUCCESS_MESSAGES[:goodbye]}"
    end
  end

  # JSON formatter for structured output
  class JsonOutputFormatter < OutputFormatter
    def initialize
      require 'json'
    end

    def format_report(robot)
      {
        status: 'success',
        type: 'report',
        data: robot_data(robot)
      }.to_json
    end

    def format_error(message, error_type = :general_error)
      {
        status: 'error',
        type: error_type.to_s,
        message: message
      }.to_json
    end

    def format_success(message = nil)
      {
        status: 'success',
        message: message
      }.to_json
    end

    def format_welcome_message(table, valid_directions)
      {
        status: 'info',
        type: 'welcome',
        data: {
          application: 'Robot Challenge Simulator',
          table: table_data(table),
          valid_directions: valid_directions,
          commands: command_descriptions
        }
      }.to_json
    end

    def format_goodbye_message
      {
        status: 'info',
        type: 'goodbye',
        message: 'Thank you for using Robot Challenge Simulator!'
      }.to_json
    end
  end

  # XML formatter for structured output
  class XmlOutputFormatter < OutputFormatter
    def format_report(robot)
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <robot_report>
          <status>success</status>
          <position>
            <x>#{robot.position.x}</x>
            <y>#{robot.position.y}</y>
          </position>
          <direction>#{robot.direction.name}</direction>
          <formatted>#{robot.report}</formatted>
        </robot_report>
      XML
    end

    def format_error(message, error_type = :general_error)
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <robot_error>
          <status>error</status>
          <type>#{error_type}</type>
          <message>#{message}</message>
        </robot_error>
      XML
    end

    def format_success(message = nil)
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <robot_response>
          <status>success</status>
          <message>#{message}</message>
        </robot_response>
      XML
    end

    def format_welcome_message(table, valid_directions)
      table_info = table_data(table)
      commands = command_descriptions

      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <robot_welcome>
          <application>Robot Challenge Simulator</application>
          <table>
            <width>#{table_info[:width]}</width>
            <height>#{table_info[:height]}</height>
          </table>
          <valid_directions>#{valid_directions.join(', ')}</valid_directions>
          <commands>
            <place>#{commands[:place]}</place>
            <move>#{commands[:move]}</move>
            <left>#{commands[:left]}</left>
            <right>#{commands[:right]}</right>
            <report>#{commands[:report]}</report>
          </commands>
        </robot_welcome>
      XML
    end

    def format_goodbye_message
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <robot_goodbye>
          <message>Thank you for using Robot Challenge Simulator!</message>
        </robot_goodbye>
      XML
    end
  end

  # CSV formatter for tabular output
  class CsvOutputFormatter < OutputFormatter
    def format_report(robot)
      "x,y,direction,formatted\n#{robot.position.x},#{robot.position.y},#{robot.direction.name},#{robot.report}"
    end

    def format_error(message, error_type = :general_error)
      "status,type,message\nerror,#{error_type},#{message}"
    end

    def format_success(message = nil)
      "status,message\nsuccess,#{message}"
    end

    def format_welcome_message(table, valid_directions)
      table_info = table_data(table)
      commands = command_descriptions

      <<~CSV
        type,key,value
        application,name,Robot Challenge Simulator
        table,width,#{table_info[:width]}
        table,height,#{table_info[:height]}
        directions,valid,#{valid_directions.join(';')}
        command,place,#{commands[:place]}
        command,move,#{commands[:move]}
        command,left,#{commands[:left]}
        command,right,#{commands[:right]}
        command,report,#{commands[:report]}
      CSV
    end

    def format_goodbye_message
      "type,message\ngoodbye,Thank you for using Robot Challenge Simulator!"
    end
  end

  # Quiet formatter (no output)
  class QuietOutputFormatter < OutputFormatter
    def format_report(_robot)
      nil
    end

    def format_error(_message, _error_type = :general_error)
      nil
    end

    def format_success(_message = nil)
      nil
    end

    def format_welcome_message(_table, _valid_directions)
      nil
    end

    def format_goodbye_message
      nil
    end
  end

  # Output formatter factory
  class OutputFormatterFactory
    def self.create(format = nil)
      case format&.to_s&.downcase
      when 'json'
        JsonOutputFormatter.new
      when 'xml'
        XmlOutputFormatter.new
      when 'csv'
        CsvOutputFormatter.new
      when 'quiet', 'none'
        QuietOutputFormatter.new
      else
        TextOutputFormatter.new
      end
    end

    def self.from_environment
      format = ENV.fetch('ROBOT_OUTPUT_FORMAT', 'text')
      create(format)
    end
  end
end
