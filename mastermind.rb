require "pry"

module Mastermind

  PEGS = ['red', 'yellow', 'blue', 'green', 'purple', 'orange']
  
  #Constants for describing peg matches
  MATCH = 2
  WRONG_POSITION = 1
  WRONG = 0

  #Constant for number of pegs in code
  NUM_PEGS = 4
  NUM_ROUNDS = 10

  class Board

    def initialize
      @guesses = []
      @responses = []
      @code = nil
    end

    private
    
    def get_guess_at(index)
      @guesses[index]
    end

    def get_response_at(index)
      return @responses[index]
    end

    public

    def place_guess(guess)
      @guesses.push(guess)
      generate_response
    end

    def place_response(response)
      @responses.push(response)
    end

    def generate_response
      response = @code.get_response_to(@guesses.last)
      place_response(response)
    end

    def get_last_guess
      @guesses.last
    end

    def get_last_response
      @responses.last
    end

    def set_code(code)
      unless @code
        @code = code
      end
    end

    def clear
      @guesses = []
      @responses = []
      @code = nil
    end

    def to_s
      str = ""
      
      i = 0
      @guesses.each do |v|
        i += 1
        str += "Guess #{i}: " + v.to_s + "\n" + "Response: " + get_response_at(i-1).to_s + "\n\n"
      end     

      return str
    end
  end

  class Peg 
=begin
Colors:
  Red
  Yellow
  Blue
  Green
  Purple
  Orange
=end
  end

  class Cell

  end

  class Code

    attr_reader :value

    def initialize(pegs = ['','','',''])
      @value = pegs
    end

    def matches?(other)
      self.value == other.value
    end

    def get_response_to(other)
      
      other = other.instance_of?(Array)? Code.new(other) : other

      response = []

      remaining_a = []
      remaining_b = []

      #Find matches
      for i in 0...self.value.length
        if self.value[i] == other.value[i]
          response.push(MATCH)
        else
          #Push non-matched pegs to temporary arrays
          remaining_a.push(self.value[i])
          remaining_b.push(other.value[i])
        end
      end

      #Find near matches
      remaining_b.each_index do |i|
        b = remaining_b[i]
        remaining_a.each_index do |j|
          a = remaining_a[j]
          if b == a 
            response.push(WRONG_POSITION)
            remaining_a.slice!(j)
            break
          end
        end
      end

      #Any remaining unmatched indexes are marked wrong
      (NUM_PEGS - response.length).times { response.push(WRONG) }

      return response
  end

    def self.get_all_codes
      guesses = []
      combination = [1,1,1,1]

      (PEGS.length**NUM_PEGS).times do
        guesses.push(self.new(combination.dup))
        combination = self.increase_combination(combination)
      end

      return guesses 
    end

    def self.increase_combination(combination, index = combination.length - 1)
      combination[index] += 1
      if combination[index] > 6
        if index > 0  
          combination[index] = 1
          return increase_combination(combination, index - 1)
        elsif index == 0
          combination[index] = 6
        end
      end
      return combination
    end
 
    def self.get_from_all(input_code, response)
      arr = all.select do |code|
        code.get_response_to(input_code) == response
      end 

     return arr
    end

    @@all = Code.get_all_codes

    def self.all
      @@all
    end

    def to_s
      self.value.to_s
    end
  end


  class Player
    
    attr_reader :name, :role, :score

    def initialize(name)
      @name = name
      @role = nil
      @score = 0
    end

    def set_role(role)
      @role = role
    end

    def score_add(score)
      @score += score
    end

    def to_s
      self.name
    end
  end

  class Computer_Player < Player

    
    def initialize()
      super("Computer")
      @last_guess = nil
      @last_response = nil
    end

    private

    def choose_random_peg 
      prng = Random.new
      return prng.rand(1...PEGS.length)
    end

    def random_guess
      prng = Random.new
      guess = []
      4.times do 
        peg = choose_random_peg
        guess.push(peg)
      end

      guess
    end

    def get_last_guess
      @last_guess
    end

    def get_last_response
      @last_response
    end

    @@possible_guesses = nil

    def get_possible_guesses(code, prev_response)
      if @@possible_guesses
        @@possible_guesses.select! { |e| e.get_response_to(code) == prev_response }
      else
        @@possible_guesses = Code.all
      end
    end

    def educated_guess(last_guess, last_response) #last_guess is an array of hashes which include :peg and :status properties
      next_guess = get_possible_guesses(last_guess, last_response).sample
    end

    public

    def make_guess(last_guess = nil, last_response = nil)
      if last_guess == nil && last_response == nil
        random_guess
      else
        guess = educated_guess(last_guess, last_response)
      end
    end

    def make_code
      random_guess
    end

  end



  class Game
    
    attr_reader :codebreaker, :codemaker, :players

    def initialize
      @players = get_players
      @board = Board.new
      @code = nil
      @codebreaker = nil
      @codemaker = nil

      play
    end  
     
    def get_players
      player_arr = []

      num_players = get_input(message: "How many players?", type: "numeric", min: 1, max: 2).to_i

      i = 0      
      num_players.times do
        i += 1
        name = get_input(message: "Choose a name for Player #{i}.", type:  "alphabet")
        player_arr.push(Player.new(name))  
      end

      if num_players == 1
        player_arr.push(Computer_Player.new())
      end

      return player_arr
    end

    def get_input(parameters)
      input = nil

      total = 5

      #get validate function
      type = parameters[:type]
      if type == "numeric"
        min = parameters[:min]
        max = parameters[:max]
        validate = -> (x) { x.to_i >= min && x.to_i <= max }
        range = "[#{min}-#{max}]: "
      elsif type == "match"
        arr = parameters[:array]
        validate = -> (x) { arr.include?(x) }
        range = "[#{arr.join("/")}]:"
      else #alphabet
        validate = -> (x) { all_letters?(x) }
        range = "[A-Za-z]:"
      end

      for i in 1..total
        puts parameters[:message] + " #{range}" 
        input = gets.chomp

        if validate.call(input)
          break
        elsif i < total
          puts "#{input} is not valid. Please enter a valid input (#{i}/#{total} attempts)"
        else
          puts "No valid input in #{total} attempts. Game will terminate"
        end

        input = nil
      end
      
      return input
    end    
    
    def get_code_input
      code_input = Array.new(4, "_")
      i = 0
      NUM_PEGS.times do
        puts "Current input: [" + code_input[0].to_s + ", " + code_input[1].to_s  + ", " + code_input[2].to_s + ", " + code_input[3].to_s + "]"
        code_input[i] = get_input(message: "Enter a number for peg No. #{i+1}.", type: "numeric", min: 1, max: 6).to_i
        i += 1
      end
      
      return code_input 
    end

    def all_letters?(str)
      chars = ("A".."Z").to_a.concat(("a".."z").to_a)
        
      str.split("").all? do |char|
        chars.include?(char)
      end

    end

    def set_code 
      if @codemaker.instance_of?(Player)
        puts "#{@codemaker}, please enter your mastercode:"
        code = get_code_input
      else
        code = @codemaker.make_code
      end

      @code = Code.new(code)
      @board.set_code(@code)
    end

    def play
      set_player_roles
      
      i = 0
      2.times do
        puts "#{self.players[i]} is the #{self.players[i].role}"
        i += 1
      end
  
      round_num = 0

      set_code

      while round_num < NUM_ROUNDS && !win?
        round_num += 1
        play_round
        update_display
        puts "Press any key to continue."
        gets
      end

      score(round_num)      
      game_results(round_num)

      if play_again?
        restart
      else
        end_game
      end
    end

    def play_again?
      answer = get_input(message: "Play again?", type: "match", array: ["y", "n"])
      return answer == "y"
    end
    
    def restart
      @board.clear
      play
    end

    def end_game
      puts "Thanks for playing!"
    end

    def score(round_num)
      @codemaker.score_add(round_num)
    end

    def score_report
      puts "Current Scores"
      i = 0
      2.times do
        puts "#{self.players[i]}: #{self.players[i].score}"
        i += 1
      end
    end

    def game_results(round_num)
      update_display

      if round_num >= NUM_ROUNDS
        puts "#{@codemaker} wins!"
        puts "The code was: #{@code}"
      else
        puts "#{@codebreaker} correctly guessed the code in #{round_num} turns!"
      end
        puts "Game Over!"

      score_report
    end


    def set_player_roles
      if self.codebreaker && self.codemaker
        temp_val = self.codebreaker
        set_codebreaker(self.codemaker)
        set_codemaker(temp_val)
      else
        choice = get_input( message: "#{self.players.first}, would you like to be the codebreaker(1) or codemaker(2)?", type: "numeric", min: 1, max: 2).to_i

        if choice == 1
          set_codebreaker(self.players.first)
          set_codemaker(self.players.last)
        else
          set_codebreaker(self.players.last)
          set_codemaker(self.players.first)
        end
      end
    end

    def set_codebreaker(player)
      @codebreaker = player
      player.set_role("codebreaker")
    end

    def set_codemaker(player)
      @codemaker = player
      player.set_role("codemaker")
    end

    def play_round
      update_display

      if self.codebreaker.instance_of?(Player)
        puts "#{@codebreaker}, make your guess:"
        guess = get_code_input
      else
        last_guess = @board.get_last_guess
        last_response = @board.get_last_response
        guess = @codebreaker.make_guess(last_guess, last_response)
      end
      
      @board.place_guess(guess)
    end

    def win?
      last_response = @board.get_last_response
      
      if last_response == [MATCH, MATCH, MATCH, MATCH]
        return true
      else
        return false
      end
    end

  def update_display
    system "clear" 
    puts @board
  end

  end

end

Mastermind::Game.new()

