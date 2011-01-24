# class overwrites aka monkey patches
# hack: store sinatra instance in global var $url_provider to make url_for and halt methods accessible
before {
  raise "should not happen, url provider already differently initialized "+
    $url_provider.request.host.to_s+" != "+self.request.host.to_s if
    $url_provider and $url_provider.request.host!=self.request.host and 
    $url_provider.request.script_name!=self.request.script_name
  $url_provider = self
  # stupid internet explorer does not ask for text/html, add this manually 
  request.env['HTTP_ACCEPT'] += ";text/html" if request.env["HTTP_USER_AGENT"]=~/MSIE/
}

# Error handling
# Errors are logged as error and formated according to acccept-header
# Non OpenTox::Errors (defined in error.rb) are handled as internal error (500), stacktrace is logged
# IMPT: set sinatra settings :show_exceptions + :raise_errors to false in config.ru, otherwise Rack::Showexceptions takes over
error Exception do
  error = request.env['sinatra.error']
  # log error to logfile
  LOGGER.error error.class.to_s+": "+error.message
  # log backtrace only if code is 500 -> unwanted (Runtime)Exceptions and internal errors (see error.rb)
  LOGGER.error ":\n"+error.backtrace.join("\n") if error.http_code==500
  
  actor = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}#{request.env['REQUEST_URI']}"
  rep = OpenTox::ErrorReport.new(error, actor)

  case request.env['HTTP_ACCEPT']
  when /rdf/
    content_type 'application/rdf+xml'
    halt error.http_code,rep.to_xml
  when /html/
    content_type 'text/html'
    halt error.http_code,(OpenTox.text_to_html rep.to_yaml)
  else
    content_type 'application/x-yaml'
    halt error.http_code,rep.to_yaml
  end
end

class String
  def task_uri?
    self.uri? && !self.match(/task/).nil?
  end
  
  def dataset_uri?
   self.uri? && !self.match(/dataset/).nil?
  end
 
  def self.model_uri?
   self.uri? && !self.match(/model/).nil?
  end

  def uri?
    begin
      u = URI::parse(self)
      return (u.scheme!=nil and u.host!=nil)
    rescue URI::InvalidURIError
      return false
    end
  end

  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end

require 'logger'
# logging
#class Logger
class OTLogger < Logger
  
  def pwd
    path = Dir.pwd.to_s
    index = path.rindex(/\//)
    return path if index==nil
    path[(index+1)..-1]
  end
  
  def trace()
    lines = caller(0)
    n = 2
    line = lines[n]
    
    while (line =~ /spork.rb/ or line =~ /create/ or line =~ /overwrite.rb/)
      n += 1
      line = lines[n]
    end
  
    index = line.rindex(/\/.*\.rb/)
    return line if index==nil
    line[index..-1]
  end
  
  def format(msg)
    pwd.ljust(18)+" :: "+msg.to_s+"           :: "+trace
  end
  
  def debug(msg)
    super format(msg)
  end
  
  def info(msg)
    super format(msg)
  end
  
  def warn(msg)
    super format(msg)
  end

  def error(msg)
    super format(msg)
  end

end

