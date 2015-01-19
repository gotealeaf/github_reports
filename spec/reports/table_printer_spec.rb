require 'active_support/core_ext/string/strip'

require 'reports/table_printer'

module Reports
  RSpec.describe TablePrinter do

    let(:io) { StringIO.new }
    let(:table) { TablePrinter.new(io) }

    let(:data) do
      { key1: 12345, key2: 56789 }
    end

    it "prints a simple table" do
      table.print(data)

      io.rewind

      expect(io.read).to eq(<<-TXT.strip_heredoc)
        56789   82.1%  key2
        12345   17.9%  key1
      TXT
    end

    it "prints a total row" do
      table.print(data, total: true)

      io.rewind

      expect(io.read).to eq(<<-TXT.strip_heredoc)
        56789   82.1%  key2
        12345   17.9%  key1

        69134  100.0%  total
      TXT
    end

    it "prints a humanized table" do
      data[:key3] = 123
      data[:key4] = 1234567890

      table.print(data, total: true, humanize: true)

      io.rewind

      expect(io.read).to eq(<<-TXT.strip_heredoc)
        1.15 GB  100.0%  key4
        55.5 KB    0.0%  key2
        12.1 KB    0.0%  key1
         123 B     0.0%  key3

        1.15 GB  100.0%  total
      TXT
    end

    it "prints a title" do
      table.print(data, title: "A Summary Table")

      io.rewind

      expect(io.read).to eq(<<-TXT.strip_heredoc)
        * * * A Summary Table * * *
        56789   82.1%  key2
        12345   17.9%  key1
      TXT
    end
  end
end
