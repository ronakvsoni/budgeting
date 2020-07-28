class CLI
    def welcome
        puts ""
    end
end


def art_of_budgeting
    logo = File.read("./db/budgeting.txt")
    puts logo
  end