require 'lucene'

#require 'lucene/jars'
#require 'lucene/field_infos'

module Lucene
  
  class Expression
    attr_accessor :left, :right, :op, :query
  
    def self.new_complete(left, op, right)
      expr = Expression.new
      expr.left = left
      expr.op = op
      expr.right = right
      expr
    end
  
    def self.new_uncomplete(left, query)
      expr = Expression.new
      expr.left = left
      expr.query = query
      expr
    end
  
    def ==(other)
      puts "== '#{other}' type: #{other.class.to_s}"
      @op = :==
        @right = other
      @query
    end
  
    def >(other)
      puts "> '#{other}'"
      @op = :>
        @right = other
      @query
    end
  
    
    def to_lucene(field_infos)
      $LUCENE_LOGGER.debug{"QueryDSL.to_lucene '#{to_s}'"}
      
      if @left.kind_of? Lucene::Expression
        left_query = @left.to_lucene(field_infos)
        raise ArgumentError.new("Right term is not an Expression, but a '#{@right.class.to_s}'") unless @right.kind_of? Lucene::Expression
        right_query = @right.to_lucene(field_infos)
        query = BooleanQuery.new
        query.add(left_query, BooleanClause::Occur::MUST)
        query.add(right_query, BooleanClause::Occur::MUST)
        return query
      else
        field_info = field_infos[@left]
        field_info.convert_to_query(@left, @right)
      end
    end

    def to_s
      "(#@left #@op #@right)"
    end
  end
  
  class QueryDSL
    attr_reader :stack 
    
    def initialize
      @stack = []
      #yield self
    end
    
    def self.find(field_infos = FieldInfos.new(:id), &expr) 
      exp = QueryDSL.parse(&expr)
      
      
      exp.to_lucene(field_infos)
    end
      
    
  
    def self.parse(&query)
      query_dsl = QueryDSL.new
      query_dsl.instance_eval(&query)
      query_dsl.stack.last
    end
    
    def method_missing(methodname, *args)
      puts "called '#{methodname}'"
      expr = Expression.new_uncomplete(methodname, self)
      @stack.push expr
      expr
    end
  
    def ==(other)
      puts "WRONG == '#{other}'"
    end
    
    def <=>(to)
      puts "<=> #{to} type #{to.class.to_s}"
      puts "Stack top #{@stack.last}"
      from = @stack.last.right
      @stack.last.right = Range.new(from, to)
      @stack.last
    end
  
  
    def &(other)
      raise ArgumentError.new("Expected at least two expression on stack, got #{@stack.size}") if @stack.size < 2
      right = @stack.pop
      left = @stack.pop
      expr = Expression.new_complete(left, :&, right)
      @stack.push expr
      puts "& '#{other}'"
      self
    end

    def to_s
      @stack.last.to_s
    end
      
  end
  
  
end
