class Interface
  attr_reader :prompt

  def initialize
    @prompt = TTY::Prompt.new(enable_color: true)
  end
end