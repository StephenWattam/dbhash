# DBHash

DBHash is a disk-backed hash-like structure that is designed for fast append and traversal operations.

## Use
To use, simply create a DBHash::DiskHash object and point it at a directory.  If the directory does not exist, it will be created.  If it does exist and was previously a DiskHash object, it will load data from the previous instance.

    x = DBHash::DiskHash.new(directory_name, number_of_bins, number_of_files)
    x[key] = value
    x.each do |k, v|
        puts "#{k} = #{v}"
    end

Note the two tuning parameters:

 * `number_of_bins` --- This should be set to the largest number possible given the disk space, as it defines the mean length of the retrieval chains (and thus speed).  A prime number is probably prudent to work around any hash algorithm issues.
 * `number_of_files` --- The number of chain files.  The only reason to increase this beyond 1 is to allow files to be a managable size (due to filesystem limits or fragmentation)
 
Currently the system is not thread-safe.


## Structure
The disk structure is based around two logical constructs:

 1. A hash table, stored on disk as a DBHash::DiskTable object, containing records that point at...
 2. Linked lists, containing the key, value data entered into the hash

Linked lists are inserted into one or many files in an interleaved format: many lists can co-occur inside a single DBHash::InterleavedDiskList file --- this means that addition of a record requires an append write and a single pointer write, and that traversal of all keys/values is the same speed as wandering any of the individual keys.

