module Mathpack
  module IO
    @@next_stop = /[+*-\/() ]/

    @@operators = %w{+ - / ** *}
    @@delimiters = %w{, .}
    @@numbers = %w{0 1 2 3 4 5 6 7 8 9}
    @@math_constants = { 'pi' => 'Math::PI' }
    @@math_functions = { 'ln(' => 'Math.log(', 'e**(' => 'Math.exp(', 'arctg(' => 'Math.atan(', 'arcsin(' => 'Math.asin(', 'arccos(' => 'Math.acos(', 'sin(' => 'Math.sin(', 'cos(' => 'Math.cos(', 'tg(' => 'Math.tan(', 'lg(' => 'Math.log10(' }

    def self.print_table_function(params = {})
      fail 'Arrays length dismatch' if params[:x].length != params[:y].length
      File.open(params[:filename]|| 'table_function.csv', 'w+') do |file|
        file.write("#{params[:labels][:x]};#{params[:labels][:y]}\n") if params[:labels] && params[:labels][:x] && params[:labels][:y]
        params[:x].each_index do |i|
          file.write("#{params[:x][i]};#{params[:y][i]}\n")
        end
      end
    end

    def self.read_table_function(filename)
      x = []
      y = []
      data = File.read(filename)
      rows = data.split("\n")
      rows.delete!(0) unless rows[0].split(';')[0].to_f
      rows.each do |row|
        parts = row.split(';')
        x << parts[0].to_f
        y << parts[1].to_f
      end
      { x: x, y: y}
    end

    def self.parse_function(string_function)
      transformed_function = transform_string_function string_function
      produce_block(transformed_function) if is_valid_function?(transformed_function)
    end

    def self.is_valid_function?(function_string)
      str = function_string.dup
      @@math_functions.values.each do |math_func|
        str.gsub!(math_func, '(')
      end
      str.delete!(' ')
      str.gsub!('x', '')
      (@@operators + @@delimiters + @@numbers).each do |sym|
        str.gsub!(sym, '')
      end
      brackets_stack = []
      str.each_char do |bracket|
        if brackets_stack.empty?
          brackets_stack << bracket
          next
        end
        if bracket.eql? '('
          brackets_stack << bracket
        else
          if brackets_stack.last.eql? '('
            brackets_stack.pop
          else
            brackets_stack << bracket
          end
        end
      end
      str.gsub!(/[\(\)]/, '')
      brackets_stack.empty? && str.empty?
    end

    def self.transform_string_function(function_string)
      function = function_string.dup
      i_next = 0
      while i_next != function.length do
        i = function.index('^', i_next)
        break if i.nil?
        if function[i + 1].eql? '('
          function[i..i + 1] = '**('
        else
          i_next = function.index(@@next_stop, i)
          i_next = function.length unless i_next
          function[i...i_next] = '**('+ function[i + 1...i_next] + ')'
        end
      end
      @@math_functions.each do |key, value|
        function.gsub!(key, value)
      end
      @@math_constants.each do |key, value|
        function.gsub!(key, value)
      end
      function
    end

    def self.produce_block(valid_function)
      valid_function.gsub!('x', 'var')
      valid_function.gsub!('evarp', 'exp')
      calculate = -> str { ->x { eval str.gsub('var', x.to_s) } }
      calculate.(valid_function)
    end

    def self.count_diff(first_array, second_array)
      if first_array.length == second_array.length
        diff = Array.new(first_array.length){ |i| (first_array[i] - second_array[i]).abs }
      elsif first_array.length == second_array.length * 2 - 1
        diff = Array.new(second_array.length) { |i| (first_array[2 * i] - second_array[i]).abs }
      else
        fail 'Arrays length mismatch'
      end
      diff.max
    end
  end
end
