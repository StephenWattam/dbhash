


module DBHash





  # Implements a linked list format whereby
  # multiple linked lists are interleaved in a single file.
  class InterleavedDiskList

    HEADER_LENGTH      = [0, 0, 0, 0].pack('Q*').bytesize
    FULL_RECORD_LENGTH = HEADER_LENGTH + [0].pack('Q*').bytesize

    def initialize(filename)
      @filename = filename


      # Open a persistent handle
      File.open(filename, 'w'){} unless File.exist?(filename)
      @h            = File.open(filename, 'rb+')

      # Bootstrap the size entry at the end
      # of the record list
      if File.size(filename) == 0
        @n = 0
        write_size 
      else
        read_size
      end

      @h.seek(-8, IO::SEEK_END)
      @end = @h.tell
    end

    # Return the total size of this list in records
    def size
      @n
    end
    alias_method :length, :size


    # Append to a chain of records.
    #
    # header_offset must point at any header in
    # the chain.  Will read until the next pointer
    # is 0
    def append_to_chain(header_offset, hash, key, value)
      # @end always points at the last index
      record_location = @end
      # puts "Writing #{@n + 1} to #{record_location}"

      # Find the last link in the chain,
      # and write the record position into its header
      unless header_offset.nil?
        last_record_offset = find_last_link(header_offset)
        # puts "Last record: #{last_record_offset}"
        if last_record_offset
          # pry binding
          @h.seek(last_record_offset + 8 * 4, IO::SEEK_SET)
          @h.write([record_location].pack('Q'))
        end
      end
        
      # Write right at the end
      @h.seek(0, IO::SEEK_END)

      # Build record
      key_length    = key.bytesize
      value_length  = value.bytesize
      record        = [hash, key_length, value_length, 0].pack('QQQQ')

      # Write record and move internal counts up 
      @h.write(record << key << value << [@n].pack('Q'))
      @n += 1
      @end = record_location + FULL_RECORD_LENGTH + key_length + value_length
      
      
      @h.flush
      return record_location
    end


    # Iterate through all key/value pairs
    def each
      return if @n == 0
      @h.seek(0, IO::SEEK_SET)

      while(record = @h.read(FULL_RECORD_LENGTH))
         # Read data
        i, hash, key_length, value_length, next_link = from_record(record)
        # puts "READ: #{from_record(record)} (#{@h.tell}, #{next_link})"
        key   = @h.read(key_length)
        value = @h.read(value_length)

        seek_to = @h.tell
        yield(key, value)
        return if seek_to >= @end
        
        # Skip the data and read the next header
        @h.seek(seek_to, IO::SEEK_SET)
      end
    end


    # Flush all edits to disk.
    def flush
      @h.flush
    end

    # Close the underlying file handle
    def close
      @h.close
    end

  private

    # Read record data from a bytestring
    def from_record(bytes)
      bytes.unpack('QQQQQ')
    end

    # Read along a list, and return the offset
    # of the last header in it
    def find_last_link(header_offset)
      return nil if header_offset > @end

      @h.seek(header_offset, IO::SEEK_SET)
      while(record = @h.read(FULL_RECORD_LENGTH))
        # Read data
        i, hash, key_length, value_length, next_link = from_record(record)
        # puts "READ: #{header_offset} = #{from_record(record)} (#{header_offset}, #{next_link})"
        return header_offset if next_link == 0

        # Move the marker forwards.  If next link is 0 then it's the end
        header_offset += FULL_RECORD_LENGTH + key_length + value_length
        
        # Skip the data and read the next header
        @h.seek(key_length + value_length, IO::SEEK_CUR)
      end

      return header_offset
    end

    # Write the size of the overall file 
    # to the end, counted in records
    def write_size
      @h.seek(0, IO::SEEK_END)
      @h.write([@n].pack('Q'))
    end

    # Read the overall size from the end
    def read_size
      @h.seek(-8, IO::SEEK_END)
      @n = @h.read(8).unpack('Q').first
    end

  end







end

