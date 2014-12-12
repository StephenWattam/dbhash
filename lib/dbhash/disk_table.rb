

module DBHash

  # On-disk table for arbitrary data storage
  class DiskTable

    attr_reader :filename, :record_size

    NULL_BYTE = [0].pack('C')

    def initialize(filename, record_size)
      @filename     = filename
      @record_size  = record_size

      File.open(filename, 'w'){} unless File.exist?(filename)
      @h            = File.open(filename, 'rb+')
      @n            = File.size(filename) / @record_size
    end

    # Append a record
    def <<(record)
      @h.seek(0, IO::SEEK_END)
      @h.write(record)
      @n += 1
    end

    # Returns the number of records,
    # including nulls.
    def size
      @n
    end
    alias_method :length, :size

    # Write to a given id
    def []=(id, record)
      @h.seek(id * @record_size, IO::SEEK_SET)

      # # Padding
      @h.write(record)
    end

    # Iterate over the items in the table,
    # yielding key and value for
    # each
    def each_with_index
      @h.seek(0, IO::SEEK_SET)

      i = 0
      while(record = @h.read(@record_size))
        yield(record, i)
        i += 1
      end
    end

    # Look up a single id
    def [](id)
      id *= @record_size
      @h.seek(id)
      return @h.read(@record_size)
    end

    # Flush any unsynced writes.
    def flush
      @h.flush
    end

    # Close the file handle
    def close
      @h.close
    end

  end

end
