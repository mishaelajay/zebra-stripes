# frozen_string_literal: true

class PathValidator
  attr_accessor :path, :type
  def initialize(path:, type: 'dir')
    @path = Pathname.new(path)
    @type = type
  end

  def valid_path?
    return dir_exists? if type == 'dir'

    file_exists?
  end

  private

  def file_exists?
    File.exists?(path)
  end
  def dir_exists?
    Dir.exists?(path)
  end
end