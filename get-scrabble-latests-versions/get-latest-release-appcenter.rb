require 'optparse'
require 'json'
require 'time'

# BEGIN - hardcoded data that should be put in an external file
ORG_NAME = 'PierPlay'
APPS= { 
  :sandbox => {
    :iOS => 'YellowJacket-Sandbox',
    :Android => 'YellowJacket-Sandbox-1'
  },
  :qa => {
    :iOS => 'YellowJacket-QA-1',
    :iOS_Enterprise => 'YellowJacket-QA-Enterprise',
    :Android => 'YellowJacket-QA' 
  },
  :stage => {
    :iOS => 'YellowJacket-Stage-1',
    :iOS_Enterprise => 'YellowJacket-Stage-Enterprise',
    :Android => 'YellowJacket-Stage' 
  },
  :production => {
    :iOS => 'YellowJacket-Prod',
    :iOS_Enterprise => 'YellowJacket-Prod-Enterprise',
    :Android => 'YellowJacket-Prod-1'
  }
} 

# END - hardcoded data that should be put in an external file




def request_releases_json(app_name)
  cmd = "appcenter distribute releases list --app #{ORG_NAME}/#{app_name} --output json"
  `#{cmd}`
end

def parse_releases_json(releases_json)
  JSON.parse(releases_json)
end

def filter_releases_by_version(releases_data, app_version)
  releases_data
    .select {|release| release["shortVersion"]
    .start_with? app_version}
    .sort_by { |release| release["id"] }
    .reverse
end

def filter_releases_by_version(json, app_version)
  json
    .select {|release| release["shortVersion"]
    .start_with? app_version}
    .sort_by { |release| release["id"] }
    .reverse
end

def extract_release_data(releases_data)
  releases_data.map { |r| r.slice("id", "version", "shortVersion", "uploadedAt") }
end

def build_release_download_url(release_id, app_name, app_organization)
   "https://install.appcenter.ms/orgs/#{app_organization}/apps/#{app_name}/releases/#{release_id}"
end

def build_description_string(version, platform, release_data)
  if (release_data == nil)
    return "Could not find a release for version #{version} in platform #{platform}"
  end

  id = release_data['id'].to_s
  version = release_data['shortVersion']
  app_version = release_data['version']
  app_platform = release_data['platform'].gsub("_", " ")
  app_name = release_data['app_name']
  url = release_data['url']
  
  # converts to the current timezone
  date = DateTime
    .parse(release_data['uploadedAt'])
    .new_offset(DateTime.now.offset)
    .strftime('%Y-%m-%d %H:%M:%Ss (%z)')

  "#{app_platform} - #{version} (#{app_version}) - Uploaded at: #{date} - #{url}"
end

def get_release_data(app_name, app_version, app_platform)
  releases_json = request_releases_json(app_name)
  releases_data = parse_releases_json(releases_json)
  releases_data = filter_releases_by_version(releases_data, app_version)
  extract_release_data(releases_data)
end

# MAIN program start
app_data = {} 
options = {}

optparse = OptionParser.new do |opts|
  
  ENVIRONMENTS = APPS.keys.map {|k| k.to_s}

  opts.banner = "Usage: #{ARGV[0]} [options]"

  opts.on("-v", "--version VERSION", String, "Application version to fetch. Required.") do |v|
    options[:app_version] = v
  end

  opts.on("-e", "--environment ENV", ENVIRONMENTS, "Environment app to fetch. Required.") do |e|
      options[:environment] = e
  end
  
  opts.on("--print-json", "Prints json string fetched from app center to console containing all metadata from latest release") do |m|
    options[:print_metadata] = m
  end

end

begin
  optparse.parse!
  mandatory = [:app_version, :environment]
  missing = mandatory.select{ |param| options[param].nil? }
  unless missing.empty?
    raise OptionParser::MissingArgument.new(missing.join(', '))
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit
end    

g_app_version = options[:app_version]
g_environment = options[:environment]
g_print_metadata = options[:print_metadata] || false
# Send a request foreach environment asynchronous
threads = []
APPS[g_environment.to_sym].each do |app_platform, app_name|
  threads << Thread.new do 
    result = get_release_data(app_name, g_app_version, app_platform)[0]
    if (result == nil)
      app_data[app_platform] = nil
    else
      result['platform'] = app_platform.to_s
      result['app_name'] = app_name
      result['url'] = build_release_download_url(result['id'], app_name, ORG_NAME)
      app_data[app_platform] = result
    end
  end
end

print "Feching latest builds for version #{g_app_version} in environment #{g_environment} from App Center... "
threads.each { |t| t.join }
puts "Finished" 
puts

app_data.each do |platform, data|
  puts build_description_string(g_app_version, platform, data)
end

if g_print_metadata
  require 'pp'
  puts
  puts "---- Metadata start ----"
  pp app_data
  puts "---- Metadata end ----"
end
