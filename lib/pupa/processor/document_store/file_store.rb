module Pupa
  class Processor
    class DocumentStore
      # Stores JSON documents on disk.
      #
      # @see ActiveSupport::Cache::FileStore
      class FileStore
        # @param [String] output_dir the directory in which to dump JSON documents
        def initialize(output_dir)
          @output_dir = output_dir
          FileUtils.mkdir_p(@output_dir)
        end

        # Returns whether a file with the given name exists.
        #
        # @param [String] name a key
        # @return [Boolean] whether the store contains an entry for the given key
        def exist?(name)
          File.exist?(namespaced_key(name))
        end

        # Returns all file names in the storage directory.
        #
        # @return [Array<String>] all keys in the store
        def entries
          Dir.chdir(@output_dir) do
            Dir['*.json']
          end
        end

        # Returns, as JSON, the contents of the file with the given name.
        #
        # @param [String] name a key
        # @return [Hash] the value of the given key
        def read(name)
          File.open(namespaced_key(name)) do |f|
            JSON.load(f)
          end
        end

        # Returns, as JSON, the contents of the files with the given names.
        #
        # @param [String] names keys
        # @return [Array<Hash>] the values of the given keys
        def read_multi(names)
          names.map do |name|
            read(name)
          end
        end

        # Writes, as JSON, the value to a file with the given name.
        #
        # @param [String] name a key
        # @param [Hash] value a value
        def write(name, value)
          File.open(namespaced_key(name), 'w') do |f|
            JSON.dump(value, f)
          end
        end

        # Writes, as JSON, the values to files with the given names.
        #
        # @param [Hash] pairs key-value pairs
        def write_multi(pairs)
          pairs.each do |name,value|
            write(name, value)
          end
        end

        # Delete a file with the given name.
        #
        # @param [String] name a key
        def delete(name)
          File.delete(namespaced_key(name))
        end

        # Deletes all files in the storage directory.
        def clear
          Dir[File.join(@output_dir, '*.json')].each do |path|
            File.delete(path)
          end
        end

      private

        def namespaced_key(name)
          File.join(@output_dir, name)
        end
      end
    end
  end
end
