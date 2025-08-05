# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RobotChallenge::InputSource do
  describe 'InputSource base class' do
    let(:input_source_class) do
      Class.new(RobotChallenge::InputSource) do
        def each_line
          yield 'line1'
          yield 'line2'
        end

        def gets
          'test line'
        end
      end
    end

    let(:input_source) { input_source_class.new }

    describe '#each_line' do
      it 'raises NotImplementedError when not implemented' do
        base_class = described_class.new
        expect { base_class.each_line }.to raise_error(
          NotImplementedError, "#{described_class} must implement #each_line"
        )
      end

      it 'yields lines when implemented' do
        lines = []
        input_source.each_line { |line| lines << line }
        expect(lines).to eq(%w[line1 line2])
      end
    end

    describe '#gets' do
      it 'raises NotImplementedError when not implemented' do
        base_class = described_class.new
        expect { base_class.gets }.to raise_error(
          NotImplementedError, "#{described_class} must implement #gets"
        )
      end

      it 'returns line when implemented' do
        expect(input_source.gets).to eq('test line')
      end
    end

    describe '#tty?' do
      it 'returns false by default' do
        expect(input_source.tty?).to be false
      end
    end

    describe '#close' do
      it 'does nothing by default' do
        expect { input_source.close }.not_to raise_error
      end
    end
  end

  describe 'StdinInputSource' do
    let(:mock_io) { double('mock_io') }
    let(:stdin_source) { RobotChallenge::StdinInputSource.new(mock_io) }

    describe '#initialize' do
      it 'uses default stdin when no io provided' do
        source = RobotChallenge::StdinInputSource.new
        expect(source.instance_variable_get(:@io)).to eq($stdin)
      end

      it 'uses provided io' do
        expect(stdin_source.instance_variable_get(:@io)).to eq(mock_io)
      end
    end

    describe '#each_line' do
      it 'delegates to io' do
        expect(mock_io).to receive(:each_line).and_yield('line1').and_yield('line2')

        lines = []
        stdin_source.each_line { |line| lines << line }
        expect(lines).to eq(%w[line1 line2])
      end
    end

    describe '#gets' do
      it 'delegates to io' do
        expect(mock_io).to receive(:gets).and_return('test line')
        expect(stdin_source.gets).to eq('test line')
      end
    end

    describe '#tty?' do
      it 'delegates to io' do
        expect(mock_io).to receive(:tty?).and_return(true)
        expect(stdin_source.tty?).to be true
      end
    end
  end

  describe 'FileInputSource' do
    let(:temp_file) { Tempfile.new('test_input') }
    let(:file_source) { RobotChallenge::FileInputSource.new(temp_file.path) }

    before do
      temp_file.write("line1\nline2\nline3")
      temp_file.close
    end

    after do
      temp_file.unlink
    end

    describe '#initialize' do
      it 'stores file path' do
        expect(file_source.instance_variable_get(:@file_path)).to eq(temp_file.path)
      end

      it 'initializes file and lines as nil' do
        expect(file_source.instance_variable_get(:@file)).to be_nil
        expect(file_source.instance_variable_get(:@lines)).to be_nil
      end
    end

    describe '#each_line' do
      it 'yields each line from file' do
        lines = []
        file_source.each_line { |line| lines << line }
        expect(lines).to eq(%W[line1\n line2\n line3])
      end

      it 'raises ArgumentError for non-existent file' do
        source = RobotChallenge::FileInputSource.new('/nonexistent/file')
        expect { source.each_line }.to raise_error(ArgumentError, 'File not found: /nonexistent/file')
      end

      it 'raises ArgumentError for file without read permission' do
        # Create a file and remove read permissions
        restricted_file = Tempfile.new('restricted')
        restricted_file.write('test')
        restricted_file.close
        File.chmod(0o000, restricted_file.path)

        source = RobotChallenge::FileInputSource.new(restricted_file.path)
        expect { source.each_line }.to raise_error(ArgumentError, /Permission denied/)

        # Clean up
        File.chmod(0o644, restricted_file.path)
        restricted_file.unlink
      end
    end

    describe '#gets' do
      it 'returns lines sequentially' do
        expect(file_source.gets).to eq("line1\n")
        expect(file_source.gets).to eq("line2\n")
        expect(file_source.gets).to eq('line3')
        expect(file_source.gets).to be_nil
      end

      it 'caches lines on first call' do
        expect(File).to receive(:readlines).with(temp_file.path).and_return(%w[line1 line2])

        file_source.gets
        file_source.gets

        # Second call should not read file again
        expect(File).not_to receive(:readlines)
        file_source.gets
      end

      it 'returns nil when all lines read' do
        3.times { file_source.gets }
        expect(file_source.gets).to be_nil
      end
    end
  end

  describe 'StringInputSource' do
    let(:string_source) { RobotChallenge::StringInputSource.new("line1\nline2\nline3") }

    describe '#initialize' do
      it 'stores string and splits into lines' do
        expect(string_source.instance_variable_get(:@string)).to eq("line1\nline2\nline3")
        expect(string_source.instance_variable_get(:@lines)).to eq(%W[line1\n line2\n line3])
        expect(string_source.instance_variable_get(:@current_line)).to eq(0)
      end
    end

    describe '#each_line' do
      it 'yields each line from string' do
        lines = []
        string_source.each_line { |line| lines << line }
        expect(lines).to eq(%W[line1\n line2\n line3])
      end

      it 'handles empty string' do
        empty_source = RobotChallenge::StringInputSource.new('')
        lines = []
        empty_source.each_line { |line| lines << line }
        expect(lines).to eq([])
      end

      it 'handles string without newlines' do
        single_line_source = RobotChallenge::StringInputSource.new('single line')
        lines = []
        single_line_source.each_line { |line| lines << line }
        expect(lines).to eq(['single line'])
      end
    end

    describe '#gets' do
      it 'returns lines sequentially' do
        expect(string_source.gets).to eq("line1\n")
        expect(string_source.gets).to eq("line2\n")
        expect(string_source.gets).to eq('line3')
        expect(string_source.gets).to be_nil
      end

      it 'returns nil when all lines read' do
        3.times { string_source.gets }
        expect(string_source.gets).to be_nil
      end
    end
  end

  describe 'ArrayInputSource' do
    let(:array_source) { RobotChallenge::ArrayInputSource.new(%w[line1 line2 line3]) }

    describe '#initialize' do
      it 'stores array and initializes index' do
        expect(array_source.instance_variable_get(:@array)).to eq(%w[line1 line2 line3])
        expect(array_source.instance_variable_get(:@current_index)).to eq(0)
      end
    end

    describe '#each_line' do
      it 'yields each element from array' do
        lines = []
        array_source.each_line { |line| lines << line }
        expect(lines).to eq(%w[line1 line2 line3])
      end

      it 'handles empty array' do
        empty_source = RobotChallenge::ArrayInputSource.new([])
        lines = []
        empty_source.each_line { |line| lines << line }
        expect(lines).to eq([])
      end
    end

    describe '#gets' do
      it 'returns elements sequentially' do
        expect(array_source.gets).to eq('line1')
        expect(array_source.gets).to eq('line2')
        expect(array_source.gets).to eq('line3')
        expect(array_source.gets).to be_nil
      end

      it 'converts non-string elements to string' do
        mixed_source = RobotChallenge::ArrayInputSource.new([123, :symbol, 'string'])
        expect(mixed_source.gets).to eq('123')
        expect(mixed_source.gets).to eq('symbol')
        expect(mixed_source.gets).to eq('string')
      end

      it 'returns nil when all elements read' do
        3.times { array_source.gets }
        expect(array_source.gets).to be_nil
      end
    end
  end

  describe 'NetworkInputSource' do
    let(:mock_socket) { double('mock_socket') }
    let(:network_source) { RobotChallenge::NetworkInputSource.new(mock_socket) }

    describe '#initialize' do
      it 'stores socket' do
        expect(network_source.instance_variable_get(:@socket)).to eq(mock_socket)
      end
    end

    describe '#each_line' do
      it 'delegates to socket' do
        expect(mock_socket).to receive(:each_line).and_yield('line1').and_yield('line2')

        lines = []
        network_source.each_line { |line| lines << line }
        expect(lines).to eq(%w[line1 line2])
      end
    end

    describe '#gets' do
      it 'delegates to socket' do
        expect(mock_socket).to receive(:gets).and_return('test line')
        expect(network_source.gets).to eq('test line')
      end
    end

    describe '#close' do
      it 'closes socket' do
        expect(mock_socket).to receive(:close)
        network_source.close
      end
    end
  end

  describe 'InputSourceFactory' do
    describe '.create' do
      it 'creates FileInputSource for existing file path' do
        temp_file = Tempfile.new('test')
        temp_file.close

        source = RobotChallenge::InputSourceFactory.create(temp_file.path)
        expect(source).to be_a(RobotChallenge::FileInputSource)

        temp_file.unlink
      end

      it 'creates StringInputSource for non-existent file path' do
        source = RobotChallenge::InputSourceFactory.create('nonexistent.txt')
        expect(source).to be_a(RobotChallenge::StringInputSource)
      end

      it 'creates ArrayInputSource for array' do
        source = RobotChallenge::InputSourceFactory.create(%w[line1 line2])
        expect(source).to be_a(RobotChallenge::ArrayInputSource)
      end

      it 'creates StdinInputSource for IO object' do
        io = StringIO.new('test')
        source = RobotChallenge::InputSourceFactory.create(io)
        expect(source).to be_a(RobotChallenge::StdinInputSource)
      end

      it 'returns InputSource as-is' do
        original_source = RobotChallenge::StringInputSource.new('test')
        source = RobotChallenge::InputSourceFactory.create(original_source)
        expect(source).to be(original_source)
      end

      it 'raises ArgumentError for unsupported type' do
        expect { RobotChallenge::InputSourceFactory.create(123) }.to raise_error(
          ArgumentError, 'Unsupported input source type: Integer'
        )
      end
    end

    describe '.from_file_path' do
      it 'creates FileInputSource' do
        source = RobotChallenge::InputSourceFactory.from_file_path('test.txt')
        expect(source).to be_a(RobotChallenge::FileInputSource)
        expect(source.instance_variable_get(:@file_path)).to eq('test.txt')
      end
    end

    describe '.from_string' do
      it 'creates StringInputSource' do
        source = RobotChallenge::InputSourceFactory.from_string('test string')
        expect(source).to be_a(RobotChallenge::StringInputSource)
        expect(source.instance_variable_get(:@string)).to eq('test string')
      end
    end

    describe '.from_array' do
      it 'creates ArrayInputSource' do
        source = RobotChallenge::InputSourceFactory.from_array(%w[line1 line2])
        expect(source).to be_a(RobotChallenge::ArrayInputSource)
        expect(source.instance_variable_get(:@array)).to eq(%w[line1 line2])
      end
    end

    describe '.from_stdin' do
      it 'creates StdinInputSource with default stdin' do
        source = RobotChallenge::InputSourceFactory.from_stdin
        expect(source).to be_a(RobotChallenge::StdinInputSource)
        expect(source.instance_variable_get(:@io)).to eq($stdin)
      end

      it 'creates StdinInputSource with custom io' do
        custom_io = StringIO.new('test')
        source = RobotChallenge::InputSourceFactory.from_stdin(custom_io)
        expect(source).to be_a(RobotChallenge::StdinInputSource)
        expect(source.instance_variable_get(:@io)).to eq(custom_io)
      end
    end
  end
end
