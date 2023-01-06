load './app/errors/invalid_path_error.rb'

desc "Save stripe customers to a csv file"
task :save_stripe_customers_to_csv, [:target_directory] => :environment do |t, args|
  target_directory = args.target_directory || Dir.home + '/stripe_csv'
  check_path_validity(target_directory)
  puts "Your files will be downloaded to #{target_directory} in some time"
  # Fetch data and write to csv
  CustomersFetchWorker.perform_async(target_directory)
end

def check_path_validity(target_directory)
  validator_service = PathValidator.new(path: target_directory, type: 'dir')
  raise InvalidPathError unless validator_service.valid_path?
end
