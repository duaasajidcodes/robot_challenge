# frozen_string_literal: true

module RobotChallenge
  # Abstract base class for output formatters
  class OutputFormatter
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
      <<~WELCOME
        Robot Challenge Simulator
        ========================

        Commands:
          PLACE X,Y,F  - Place robot at position (X,Y) facing direction F
          MOVE         - Move robot one step forward
          LEFT         - Turn robot 90° counter-clockwise
          RIGHT        - Turn robot 90° clockwise
          REPORT       - Show current position and direction

        Table size: #{table}
        Valid directions: #{valid_directions.join(', ')}

      WELCOME
    end

    def format_goodbye_message
      "\nThank you for using Robot Challenge Simulator!"
    end
  end

  # JSON formatter for structured output
  class JsonOutputFormatter < OutputFormatter
    def format_report(robot)
      require 'json'
      {
        status: 'success',
        type: 'report',
        data: {
          position: {
            x: robot.position.x,
            y: robot.position.y
          },
          direction: robot.direction.name,
          formatted: robot.report
        }
      }.to_json
    end

    def format_error(message, error_type = :general_error)
      require 'json'
      {
        status: 'error',
        type: error_type.to_s,
        message: message
      }.to_json
    end

    def format_success(message = nil)
      require 'json'
      {
        status: 'success',
        message: message
      }.to_json
    end

    def format_welcome_message(table, valid_directions)
      require 'json'
      {
        status: 'info',
        type: 'welcome',
        data: {
          application: 'Robot Challenge Simulator',
          table: {
            width: table.width,
            height: table.height
          },
          valid_directions: valid_directions,
          commands: {
            place: 'PLACE X,Y,F - Place robot at position (X,Y) facing direction F',
            move: 'MOVE - Move robot one step forward',
            left: 'LEFT - Turn robot 90° counter-clockwise',
            right: 'RIGHT - Turn robot 90° clockwise',
            report: 'REPORT - Show current position and direction'
          }
        }
      }.to_json
    end

    def format_goodbye_message
      require 'json'
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
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <robot_welcome>
          <application>Robot Challenge Simulator</application>
          <table>
            <width>#{table.width}</width>
            <height>#{table.height}</height>
          </table>
          <valid_directions>#{valid_directions.join(', ')}</valid_directions>
          <commands>
            <place>PLACE X,Y,F - Place robot at position (X,Y) facing direction F</place>
            <move>MOVE - Move robot one step forward</move>
            <left>LEFT - Turn robot 90° counter-clockwise</left>
            <right>RIGHT - Turn robot 90° clockwise</right>
            <report>REPORT - Show current position and direction</report>
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
      <<~CSV
        type,key,value
        application,name,Robot Challenge Simulator
        table,width,#{table.width}
        table,height,#{table.height}
        directions,valid,#{valid_directions.join(';')}
        command,place,PLACE X,Y,F - Place robot at position (X,Y) facing direction F
        command,move,MOVE - Move robot one step forward
        command,left,LEFT - Turn robot 90° counter-clockwise
        command,right,RIGHT - Turn robot 90° clockwise
        command,report,REPORT - Show current position and direction
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
