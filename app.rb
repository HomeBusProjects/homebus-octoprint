require 'homebus'
require 'homebus_app'
require 'mqtt'
require 'dotenv'
require 'octoprint'
require 'json'

# http://docs.octoprint.org/en/master/api/index.html

class OctoprintHomeBusApp < HomeBusApp
  def initialize(options)
    @options = options

    Dotenv.load('.env')

    @server_url = options[:server] || ENV['OCTOPRINT_SERVER_URL']
    @api_key = options[:api_key] || ENV['OCTOPRINT_API_KEY']

    @old_substatus = ''
    @old_state = ''
    @old_file = ''
    @old_completion = ''

    super
  end

  def update_delay
    60
  end

  def setup!
    @octoprint = Octoprint.new(@server_url, @api_key)
  end

  def work!
    begin
      printer = @octoprint.api.printer
      job = @octoprint.api.job
    rescue
      if @options[:verbose]
        puts "Failure conacting server at #{@server_url}"
      end
    end

    if printer && job
      state = job["state"]
      file = job["job"]["file"]["name"]
      completion = job["progress"]["completion"]

      return if state == @old_state && file == @old_file && completion == @old_completion

      @old_state = state
      @old_file = file
      @old_completion = completion

      results = {
        id: @uuid,
        timestamp: Time.now.to_i,
        status: {
          state: state
        },
        job: {
          file: file,
          progress: completion,
          print_time: job["progress"]["printTime"],
          print_time_left: job["progress"]["printTimeLeft"],
          filament_length: job["job"]["filament"]
        },
        temperatures: {
          tool0_actual: printer["temperature"]["tool0"]["actual"],
          tool0_target: printer["temperature"]["tool0"]["target"],
          bed_actual: printer["temperature"]["bed"]["actual"],
          bed_target: printer["temperature"]["bed"]["target"]
        }
      }
      
      @mqtt.publish '/homebus/device/' + @uuid,
                    JSON.generate(results),
                    true
    end

    sleep update_delay
  end

  def manufacturer
    'HomeBus'
  end

  def model
    'Octoprint publisher'
  end

  def friendly_name
    "Octoprint server at #w{@server_url}"
  end

  def friendly_location
    'Hipster hideaway'
  end

  def serial_number
    @server_url
  end

  def pin
    ''
  end

  def devices
    [
      { friendly_name: 'Octoprint',
        friendly_location: @server_url,
        update_frequency: update_delay,
        index: 0,
        accuracy: 0,
        precision: 0,
        wo_topics: [ '/octoprint' ],
        ro_topics: [ '/octoprint/cmd' ],
        rw_topics: []
      }
    ]
  end
end
