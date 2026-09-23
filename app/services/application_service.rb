class ApplicationService
  def self.call(...)
    new(...).call
  end

  class Result
    attr_reader :data, :errors

    def initialize(success:, data: nil, errors: [])
      @success = success
      @data = data
      @errors = Array(errors)
    end

    def success?
      @success
    end

    def failure?
      !@success
    end
  end

  protected

  def success(data = nil)
    Result.new(success: true, data: data)
  end

  def failure(errors)
    Result.new(success: false, errors: errors)
  end
end
