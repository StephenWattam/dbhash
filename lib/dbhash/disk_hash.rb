


module DBHash


  # On disk hash using a fast index and multiple interleaved linked lists
  class DiskHash

    DEFAULT_NUM_BINS  = 3_152_573
    DEFAULT_NUM_FILES = 5
    DEFAULT_HASH_SEED = 7
    INDEX_FILENAME    = 'index'
    STATE_FILENAME    = 'state.yml'

    require 'yaml'
    require 'xxhash'

    # Create a new on-disk hash
    def initialize(dir, 
                   num_bins = DEFAULT_NUM_BINS, 
                   num_files = DEFAULT_NUM_FILES,
                   hash_seed = DEFAULT_HASH_SEED)
      @dir        = dir
      @num_files  = num_files
      @num_bins   = num_bins
      @hash_seed  = hash_seed

      # Load index file (created if not extant)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      @index = HashIndex.new(File.join(@dir, INDEX_FILENAME))

      # Load any bin lengths from last time if possible
      load_state || save_state

      # Load files according to the num_files entry
      @files = []
      @num_files.times do |i|
        @files << InterleavedDiskList.new(File.join(@dir, "#{i}"))
      end
    end

    # Append a value
    def []=(key, value)
      hsh  = hash_for(key)
      bin  = bin_for(hsh)
      file = file_for(bin)

      # Read from the index
      offset, last_offset, count = @index[bin]

      # puts "[#{key}] bin: #{bin}, file #{file}, offset: #{offset}, last: #{last_offset}, count: #{count}"

      # Add to the end of the chain and update the counters for the index record
      new_last    = @files[file].append_to_chain(count == 0 ? nil : last_offset, hsh, key, value)
      offset      = new_last if !offset || count == 0
      count       = (count || 0) + 1

      # Update index
      @index.put(bin, offset, new_last, count)
    end

    # Iterate over all records, even
    # partial ones
    def each
      @files.each do |f|
        f.each do |k, v|
          yield(k, v)
        end
      end
    end

    # Flush all unwritten data to disk
    def flush
      @files.each { |f| f.flush }
      @index.flush
    end

    # Close all udnerlying file handles
    def close
      @files.each { |f| f.close }
      @index.close
    end

  private

    # compute a hash for the key
    def hash_for(key)
      XXhash.xxh32(key, @hash_seed)
    end

    # Get the bin index for a hash
    def bin_for(hsh)
      (hsh % @num_bins)
    end

    # Get the file index for a hash
    def file_for(hsh)
      (hsh % @num_files)
    end

    # Load bin state
    def load_state
      filename = File.join(@dir, STATE_FILENAME)
      return nil unless File.exist?(filename)

      # Read these from YAML
      File.open(filename) do |io|
        @num_bins, @num_files, @hash_seed = YAML.load(io)
      end
    end

    # Save bin state
    def save_state
      filename = File.join(@dir, STATE_FILENAME)

      File.open(filename, 'w+') do |io|
        YAML.dump([@num_bins, @num_files, @hash_seed], io)
      end
    end


  end

  # Index for multi-list hash format.
  class HashIndex

    RECORD_SIZE = [0, 0, 0].pack('QQQ').bytesize

    def initialize(filename)
      @table = DiskTable.new(filename, RECORD_SIZE)
    end

    # Returns the number of records,
    # including nulls.
    def size
      @table.size
    end
    alias_method :length, :size

    # Overwrite or add an item to the table
    def put(key, offset, last_record, list_length)
      record = to_record(offset, last_record, list_length)
      @table[key] = record
    end

    # Return the offset, last record offset, and list length
    # for a given id
    def get(key)
      from_record(@table[key])
    end
    alias_method :'[]', :get

    # Iterate over the index listings,
    # yielding each along with an index
    def each_with_index
      @table.each_with_index do |bytes, i|
        yield(from_record(bytes), i)
      end
    end

    # Iterate over the index listings,
    # yielding the records.
    def each
      each_with_index do |record, _|
        yield(record)
      end
    end

    # Flush any unsynced writes.
    def flush
      @table.flush
    end

    # Close the file handle
    def close
      @table.close
    end


  private

    # Produce a bytestring from the file offset,
    # last record position, and list length
    def to_record(offset, last_record, list_length)
      [offset, last_record, list_length].pack('QQQ')
    end

    # Return offset, last_record, list_length from
    # bytes read from disk
    def from_record(bytes)
      return [nil, nil, nil] unless bytes
      bytes.unpack('QQQ')
    end

  end


end

