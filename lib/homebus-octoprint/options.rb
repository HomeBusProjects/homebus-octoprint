require 'homebus'

class HomebusOctoprint::Options < Homebus::Options
  def app_options(op)
    server_help = 'Server URL, like "https://ummon:5000" or "http://10.0.1.104"'
    apikey_help = 'API key from Octoprint'

    op.separator 'homebus-octoprint options:'
    op.on('-s', '--server-url SERVER-URL', server_help) { |value| options[:server] = value }
    op.on('-a', '--api-key APIKEY', apikey_help) { |value| options[:api_key] = value }
  end

  def server_help
  end

  def banner
    'HomeBus Octoprint publisher'
  end

  def version
    HomebusOctoprint::VERSION
  end

  def name
    'homebus-octoprint'
  end
end
