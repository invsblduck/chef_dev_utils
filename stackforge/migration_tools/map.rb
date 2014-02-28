#!/usr/bin/ruby

require 'optparse'
require 'ap'

@regex = false
@debug = false

def debug(msg)
  puts "DEBUG: #{msg}" if @debug
end

OptionParser.new(nil, 25) do |opts|
  opts.banner = "usage: #{$0} [options] <file1_scoped> <file2_scoped>"
  opts.on('-d', '--debug', "Enable debugging output") { @debug = true }
  opts.on('-r', '--regex', '--loose', "Enable loose key matching") { @regex = true }
  opts.on('-h', '--help', "This useless garbage") { puts opts; exit }
  begin
    ARGV = ['-h'] if ARGV.empty?
    opts.parse!(ARGV)
  rescue OptionParser::ParseError => e
    $stderr.puts e.message, "\n", opts
    exit(-1)
  end
end

if ARGV.length != 2
  puts "usage: #{$0} [options] <file1_scoped> <file2_scoped>"
  exit 1
end

ARGV.each do |f|
  if ! File.exists? f
    puts "#{f} does not exist"
    exit 1
  end
end

@hash1  = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
@hash2  = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
@common = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

@lsb = {'codename'=>'precise'}
@kernel = {'release'=>'3.8', 'machine'=>'x86_64'}
@platform = "ubuntu"
@platform_family = "debian"

def platform?
  "ubuntu"
end
def platform_family?
  "debian"
end

require_relative ARGV[0].sub(/\.rb$/,'')
require_relative ARGV[1].sub(/\.rb$/,'')
require_relative "stack_common_scoped"

@h1_path = []
@h2_path = []
@matches = []
@partial = []

def same_parent_key?
  p1=@h1_path[-2]
  p2=@h2_path[-2]
  if p1 == p2
    return true
  else
    case p1 
    when 'cinder'
      p2 == 'block-storage' and return true
    when 'glance'
      p2 == 'image' and return true
    when 'horizon'
      p2 == 'dashboard' and return true
    when 'keystone'
      p2 == 'identity' and return true
    when 'nova'
      p2 == 'compute' and return true
    when 'neutron'
      p2 == 'network' and return true
    when 'ovs'
      p2 == 'openvswitch' and return true
    else
      return false
    end
  end
end

def walk_h2_and_compare(hash, source_key)

  debug("walk_h2: source_key=`#{source_key}'")

  hash.each do |k,v|
    debug("walk_h2: iterating on k=`#{k}' v=`#{v}'")

    @h2_path << k
    debug("walk_h2: pushed @h2_path=`#{@h2_path}'")

    if v.class == Hash
      debug("walk_h2: v is a Hash; recursing")
      walk_h2_and_compare(v, source_key) 
    else
      if (k == source_key)
        debug("walk_h2: k == source_key, adding to @matches")
        @matches << {path:@h2_path.join('.'), value:v, parent:same_parent_key?}
      elsif @regex
        if k.class == String
          if ((k =~ /#{source_key.gsub(/_/,'|')}/) or
              (source_key =~ /#{k.gsub(/_/,'|')}/))

            debug("walk_h2: found partial match")
            @partial << "#{@h2_path.join('.')} = #{v}"
          end
        end
      end
      @h2_path.pop
      debug("walk_h2: popped @h2_path=`#{@h2_path}'")
    end
  end
  @h2_path.pop
  debug("walk_h2: popped @h2_path=`#{@h2_path}'")
end

def walk_h1(hash)
  hash.each do |k,v|
    debug("walk_h1: k=`#{k}' v=`#{v}'")

    @h1_path << k
    mypath = @h1_path.join('.')

    debug("walk_h1: pushed @h1_path=`#{@h1_path}'")

    if v.class == Hash
      debug("walk_h1: v is a Hash; recursing")
      walk_h1(v)
    else
      @h2_path = []
      @matches = []
      @partial = []

      debug("walk_h1: calling walk_h2 for key `#{k}'")
      walk_h2_and_compare(@hash2, k)

      if @matches.any?
        debug("walk_h1: There are matches for `#{mypath}'")
        if @matches.length == 1
          h = @matches[0]
          debug("walk_h1: found single match: `#{h}'")
          if v == h[:value]
            debug("walk_h1: values are the same!")
            @fd.puts "#{mypath} > #{h[:path]}"
          else
            debug("walk_h1: values differ")
            @fd.puts "+#{mypath} (#{v}) > #{h[:path]} (#{h[:value]})"
          end
        else
          debug("walk_h1: multiple matches; looking for matching parents")

          # find if any have a matching parent
          parent_match = false
          @matches.each do |hsh|
            if hsh[:parent]
              debug("walk_h1: found a parent match!")
              parent_match = true
              if v == hsh[:value]
                debug("walk_h1: values are the same!")
                @fd.puts "#{mypath} > #{hsh[:path]}"
              else
                debug("walk_h1: values differ")
                @fd.puts "+#{mypath} (#{v}) > #{hsh[:path]} (#{hsh[:value]})"
              end
              break
            end
          end
          unless parent_match
            debug("walk_h1: !!! NO MATCH FOUND FOR `#{mypath}'")
            @fd.puts " ! #{mypath} = #{v}"
          end
        end
      else
        debug("walk_h1: !!! NO MATCHES FOR `#{mypath}'")
        # print a bang !
        @fd.puts " ! #{mypath} = #{v}"
      end

      print "\e[36m#{mypath}\e[0m = ", v.nil? ? "nil" : v, " "
      if @matches.any? or @partial.any?
        suggestions = []
        @matches.each do |hsh|
          suggestions << "#{hsh[:path]} = #{hsh[:value]}"
        end
        suggestions << @partial
        ap(suggestions.flatten)
      else
        puts
      end

      @h2_path = []
      @matches = []
      @partial = []
      walk_h2_and_compare(@common, k)
      if (@matches.any? or @partial.any?)
        suggestions = []
        @matches.each do |hsh|
          suggestions << "#{hsh[:path]} = #{hsh[:value]}"
        end
        suggestions << @partial
        puts "\e[30m(see also: #{suggestions.flatten})\e[0m"
      end

      @h1_path.pop
    end
  end
  @h1_path.pop
end

@fd = File.open(ARGV[0].sub(/_scoped/,'').sub(/\.rb$/,''), "w")
walk_h1 @hash1
@fd.close
