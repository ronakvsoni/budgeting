class Interface
  attr_reader :prompt

  def initialize
    @prompt = TTY::Prompt.new(enable_color: true)
  end
end


def art_of_budgeting
  logo = File.read("./db/budgeting.txt")
  puts logo
end