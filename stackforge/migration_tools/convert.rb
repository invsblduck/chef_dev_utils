#!/usr/bin/ruby

require 'yaml'
require 'pp'

if ARGV.length != 3
  puts "usage: #{$0} <file1_scoped> <file2_scoped> <map_final>"
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
#require_relative "stack_common_scoped"
require_relative "cookbook-openstack-common_scoped"

#pp @hash1
#exit(0)

def query_hash(string, hash)
  string.split('.').reduce({}) do |memo, k|
    if memo.empty?
      memo = hash[k]
    else
      memo = memo[k]
    end
    memo
  end
end

def find_value(string, hash)
  val = query_hash(string, hash)

  if val.class == Hash and val.empty?
    # try @common hash
    puts "(pulling from openstack-common)"
    val = query_hash(string, @common)
  end
  val
end

def trigger_new_attr
  if @parsing_note
    puts
    puts "%%%%%%%"
    @note_data.each do |l|
      puts l
    end
    puts "%%%%%%%"
    @yaml_hash[@current_var]['notes'] = @note_data
  end
  @parsing_note = false
  @note_data = []
  puts "\n\n"
  puts @current_line
  puts
end

@yaml_hash = {}
@current_line = ''
@current_var = ''
@parsing_note = false
@note_data = []

File.open(ARGV[2]).readlines.each do |l|
  @current_line = l.chomp
  var1 = var2 = val1 = val2 = typ1 = typ2 = nil

  if @current_line =~ /^([\w.-]+)\s+>\s+([\w.-]+)/
    # direct mapping
    var1 = $1
    var2 = $2

    trigger_new_attr
    @current_var = var1

    val1 = find_value(var1, @hash1)
    typ1 = val1.class

    val2 = find_value(var2, @hash2)
    typ2 = val2.class

    puts "==> direct mapping"
    puts "    #{var1} = #{val1} (#{typ1})"
    puts "    #{var2} = #{val2} (#{typ2})"

  elsif @current_line =~ /^\+([\w.-]+)\s+\(.*?\)\s+>\s+([\w.-]+)\s+\(.*?\)/
    # different defaults
    var1 = $1
    var2 = $2

    trigger_new_attr
    @current_var = var1

    val1 = find_value(var1, @hash1)
    typ1 = val1.class

    val2 = find_value(var2, @hash2)
    typ2 = val2.class

    puts "==> VARYING defaults"
    puts "    #{var1} = #{val1} (#{typ1})"
    puts "    #{var2} = #{val2} (#{typ2})"

  elsif @current_line =~ /^\s+!\s+([\w.-]+)\s+/
    # no mapping
    var1 = $1

    trigger_new_attr
    @current_var = var1

    val1 = find_value(var1, @hash1)
    typ1 = val1.class

    puts "==> NO MAPPING"
    puts "    #{var1} = #{val1} (#{typ1})"

  elsif @current_line =~ /^\s*#(.*NOTE.*)?/
    # note
    puts @current_line
    if @current_line =~ /NOTE/
      @parsing_note = 
      @note_data = [@current_line.gsub(/^\s*#\s*\^NOTE:\s*/, '')]
    else
      if @parsing_note
        @note_data << @current_line.gsub(/^\s*#\s*/, '')
      end
    end
  else
    # unknown line
    puts "==> ???"
  end

  if ! @parsing_note
    @yaml_hash[var1] = {
      default: val1,
      type: typ1.to_s,
      stack_name: var2,
      stack_default: val2,
      stack_type: (typ2 and typ2.to_s || nil),
      notes: [],
    }
  end
end

#puts @yaml_hash.keys.sort

File.open(ARGV[0].sub(/_scoped/,'').sub(/\.rb$/,'') + ".yml", "w") do |fd|
  fd.puts YAML.dump(@yaml_hash)
end
 
#@fd.close
