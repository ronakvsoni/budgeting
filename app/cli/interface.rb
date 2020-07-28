class Interface
  attr_reader :prompt

  def initialize
    @prompt = TTY::Prompt.new(enable_color: true)

    # Add welcome message to initialize
    ap 'Welcome to Budgeting!'
  end

  def art_of_budgeting
    logo = File.read('./cli/budgeting.txt')
    puts logo
  end
end