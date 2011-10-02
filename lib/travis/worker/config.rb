require 'yaml'
require 'hashr'

module Travis
  module Worker
    class Config < Hashr
      module Vms
        def count
         self[:count]
        end

        def names
          (1..count.to_i).map { |num| "#{Travis::Worker.config.env}-#{num}" }
        end

        def provision?
          !recipes.empty? && File.directory?(cookbooks)
        end
      end

      define :queue     => 'builds',
             :messaging => { :username => 'guest', :password => 'guest', :host => 'localhost' },
             :shell     => { :buffer => 0 },
             :timeouts  => { :before_script => 300, :after_script => 120, :script => 600, :install_deps => 300 },
             :vms       => { :name_prefix => 'worker', :count => 1, :base => 'lucid32', :memory => 1536, :cookbooks => 'vendor/cookbooks', :log_level => 'info', :json => {}, :_include => Vms }

      def initialize
        super(read)
      end

      protected

        LOCATIONS = ['./config/', '~/.']

        def read
          local = read_yml(path)
          env   = local['env']
          local = local[env] || {}
          read_yml(path(env)).merge(local.merge('env' => env))
        end

        def read_yml(path)
          YAML.load_file(File.expand_path(path))
        end

        def path(environment = nil)
          filename = ['worker', environment, 'yml'].compact.join('.')
          paths = LOCATIONS.map { |path| "#{path}#{filename}" }
          paths.each { |path| return path if File.exists?(path) }
          raise "Could not find a configuration file. Valid paths are: #{paths.join(', ')}"
        end
    end
  end
end
