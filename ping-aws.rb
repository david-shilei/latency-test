require 'json'
require 'terminal-table'
require 'trollop'

PING_CNT=5
LATENCY_STATUS=/^round-trip min\/avg\/max\/stddev = [\d.]+\/([\d.]+)\/[\d.]+\/[\d.]+ ms/
 
def ping(host)
 cmd = "/sbin/ping -c #{PING_CNT} #{host}"
 # puts "execute command: #{cmd}"
 `#{cmd}`
end
 
def parse(ping_result)
  # >> passed
  # 4 packets transmitted, 4 packets received, 0.0% packet loss
  # round-trip min/avg/max/stddev = 98.136/106.188/117.813/7.498 ms
  # ---
  # >> failed
  # 4 packets transmitted, 0 packets received, 100.0% packet loss
  lines = ping_result.split('\n')
  # try match latency status
  md = lines[-1].match(LATENCY_STATUS)
  if md
    md[1].to_f
  else
    Float::INFINITY
  end
end
 
def main
  opts = Trollop.options do
    banner <<-EOS
Test Ping latency

Usage:
    ping-aws.rb
    EOS
    opt :csv, "Write results to csv files", :default => false
    opt :analysis, "Use R to do analysis", :default => false
  end

  instances = JSON.parse(File.open(File.dirname(__FILE__) + "/instances.json").read)
  metrics = {}
  instances.each do |name, host|
    puts "Ping #{name}: #{host} ..."
    output = ping(host)
    latency = parse(output)
    metrics[name] = latency

    next unless opts[:csv]

    time_stamp = Time.now.strftime "%Y-%m-%d %H:%M"
    csv_file = File.dirname(__FILE__) + "/results/ping-#{name}.csv"
    File.open(csv_file, "a") do |file|
      file.puts("#{time_stamp},#{latency}")
    end

    next unless opts[:analysis]
    
    puts "Analysising #{csv_file}"
    analysis_script = File.dirname(__FILE__) + "/results/analysis.R"
    cmd = "/usr/bin/Rscript #{analysis_script} #{csv_file}"
    `#{cmd}`
  end

  rows = []
  rows << ['Region', 'Ping(ms)']
  metrics.sort_by { |k, v| v }.each do |k, v|
    rows << [k, v == Float::INFINITY ? '-' : v]
  end
  table = Terminal::Table.new :rows => rows
  puts table
end

if $0 == __FILE__
  main
end
