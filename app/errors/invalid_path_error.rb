class InvalidPathError < StandardError
  def initialize(msg='The path you provided does not exist')
    super(msg)
  end
end
