require_all './app/cli/modules/'
#TODO: Make expenses searchable by name or category

class Interface
  attr_reader :prompt
  attr_accessor :session, :user

  include BankAccountInterface
  include BudgetInterface
  include TransactionInterface
  include UserInterface

  def initialize
    @prompt = TTY::Prompt.new(enable_color: true)
  end
  
  #Start a session with this instance of the Interface
  def new_session
    self.system_clear
    self.session = {
      #When this is true, the session will quit
      quit: false,

      #The user for the current session
      user: nil,

      #These tags tell the session which object to focus
      focus: {
        budget: nil,
        category: nil,
        expense: nil,
        bank_account: nil,
        transaction: nil
      },

      #Used for opening various windows - initializes with a first-time main menu
      window: 'main_menu',
      args: { first: true }
    }

    until self.session[:quit] do
      self.refresh_models
      self.send(self.session[:window], self.session[:args])
    end

    self.system_clear
    prompt.say('Bye for now!')
  end

  #Quit a session
  def quit_session
    self.session[:quit] = true
  end

  #Open a window
  def open_window(window, args = {})
    self.session[:window], self.session[:args] = window, args
  end

  #Set the focus for a series of windows
  def focus(p = {})
    p.each { |k, v| self.session[:focus][k] = v }
  end

  def reset_focus
    self.session[:focus] = {
      budget: nil,
      category: nil,
      expense: nil,
      bank_account: nil,
      transaction: nil
    }
  end

  #Grab a current focus by symbol
  def session_focus(sym)
    self.session[:focus][sym]
  end

  #Clear the window
  def system_clear
    system (Gem.win_platform? ? 'cls' : 'clear')
  end

  #Refresh any models the session currently has in focus before each menu loads
  def refresh_models
    self.session[:focus].each { |model, object| object.reload if object }
  end

  #Opening art
  def art_of_budgeting
    self.system_clear
    logo = File.read('./app/cli/budgeting.txt')
    puts logo
    sleep 5
  end

  #Main menu
  def main_menu(p = {})
    self.system_clear

    if p[:first]
      open_message = 'Hi! Are you new here?'
      open_choice_1 = 'Brand new!'
      open_choice_2 = 'Nope! Sign me in, please.'
    else
      open_message = 'Welcome back! Please select an option:'
      open_choice_1 = 'Create a new account, please.'
      open_choice_2 = 'Sign me in!'
    end

    open_choice = prompt.select(open_message, cycle: true) do |s|
      s.choice open_choice_1, 'create_user'
      s.choice open_choice_2, 'sign_in'
      s.choice 'Exit.', false
    end

    !open_choice ? self.quit_session : self.open_window(open_choice)
  end
end
