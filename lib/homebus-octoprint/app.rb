require 'homebus'
require 'dotenv'

require 'octoprint'

# http://docs.octoprint.org/en/master/api/index.html

class HomebusOctoprint::App < Homebus::App
  DDC_3DPRINTER = 'org.homebus.experimental.3dprinter'
  DDC_COMPLETED_JOB = 'org.homebus.experimental.3dprinter-completed-job'
  DDC_COMPLETED_JOB_HISTORY = 'org.homebus.experimental.3dprinter-completed-job-history'

  def initialize(options)
    @options = options

    Dotenv.load('.env')

    @server_url = options[:server] || ENV['OCTOPRINT_SERVER_URL']
    @api_key = options[:api_key] || ENV['OCTOPRINT_API_KEY']

    @old_substatus = ''
    @old_state = ''
    @old_file = ''
    @old_completion = ''

    @device = Homebus::Device.new(name: "Octoprint server at %w{@server_url}",
                                  manufacturer: 'Homebus',
                                  model: 'Octoprint publisher',
                                  serial_number: @server_url
                                 )

    super
  end

  def update_interval
    60
  end

  def setup!
    @octoprint = Octoprint.new(@server_url, @api_key)

    @state.state[:history] ||= Array.new
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
      pp 

      state = job["state"]
      file = job["job"]["file"]["name"]
      completion = job["progress"]["completion"]

      return if state == @old_state && file == @old_file && completion == @old_completion

      @old_state = state
      @old_file = file
      @old_completion = completion

      payload = {
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

      @device.publish! DDC_3DPRINTER, payload

      if options[:verbose]
        puts payload
      end

      if completion == 100
        completed_job job
      end
    end

    sleep update_interval
  end

  def completed_job(job)
    job_info = {
      state: job["state"],
      start_time: Time.now.to_i - job["progress"]["printTime"] ,
      end_time: Time.now.to_i,
      material: [
        { type: 'filament',
          quantity: job["job"]["filament"]["tool0"]["length"],
          units: 'mm'
        }
      ]
    }

    
    @state.state[:history] = @state.state[:history].push(job_info).last(10)
    @state.commit!

    pp job_info

    @device.publish! DDC_COMPLETED_JOB, job_info
    @device.publish! DDC_COMPLETED_JOB_HISTORY, @state.state[:history]
  end

  def name
    'Octoprint publisher'
  end

  def publishes
    [ DDC_3DPRINTER, DDC_COMPLETED_JOB, DDC_COMPLETED_JOB_HISTORY ]
  end

  def devices
    [ @device ]
  end
end
