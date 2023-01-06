require 'rails_helper'

RSpec.describe PathValidator do
  context 'Invalid paths' do
    let(:invalid_dir_path) { random_string + "/#{random_string}"}
    let(:invalid_file_path) { random_string + "/#{random_string}.jpg"}

    it 'valid_path? should return falses' do
      fpv_service = PathValidator.new(path: invalid_file_path, type: 'file')
      expect(fpv_service.valid_path?).to be false
      fpv_service.path = invalid_dir_path
      fpv_service.type = 'dir'
      expect(fpv_service.valid_path?).to be false
    end
  end

  context 'Valid paths' do
    let(:valid_dir_path) { Dir.home }
    let(:valid_file) { file_fixture('some_csv.csv') }
    let(:valid_file_path) { valid_file.realpath.to_s }

    it 'valid_path? should return false' do
      fpv_service = PathValidator.new(path: valid_dir_path, type: 'dir')
      expect(fpv_service.valid_path?).to be true
      fpv_service.path = valid_file_path
      fpv_service.type = 'file'
      expect(fpv_service.valid_path?).to be true
    end
  end

  def random_string
    SecureRandom.alphanumeric(20)
  end
end
