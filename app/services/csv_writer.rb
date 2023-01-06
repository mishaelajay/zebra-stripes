require 'csv'
class CsvWriter
  attr_accessor :directory_path, :filename
  def initialize(directory_path:, filename:)
    @directory_path = directory_path
    @filename = filename
  end

  def push_headers
    CSV.open(full_path, 'wb') do |csv|
      csv << headers
    end
  end

  def push_batch(customers)
    CSV.open(full_path, 'ab') do |csv|
      customers.each do |customer|
        csv << customer.values
      end
    end
  end

  private

  def full_path
    directory_path + "/#{filename}"
  end

  def headers
    %w[id name email phone address account_balance currency]
  end
end