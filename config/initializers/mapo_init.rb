Mapotempo::Application.config.delayed_job_use = Rails.env.development?
Delayed::Worker.max_attempts = 1

Mapotempo::Application.config.max_destinations = 50000

Mapotempo::Application.config.self_care = false # If true, allow subscription and resiliation by the user himself
Mapotempo::Application.config.manage_vehicles_only_admin = false # If true, only admin can add/remove vehicles

Mapotempo::Application.config.welcome_url = 'https://www.mapotempo.com/app-news/'

Mapotempo::Application.config.action_mailer.delivery_method = :letter_opener if Rails.env == 'development'

def cache_factory(_namespace, _expires_in)
  ActiveSupport::Cache::NullStore.new
end

if ENV['RAILS_ENV'] != 'test'
  Mapotempo::Application.config.geocoder.url = 'http://geocode.beta.mapotempo.com/0.1'
  Mapotempo::Application.config.geocoder.api_key = 'demo'
  # Mapotempo::Application.config.geocoder.cache = cache_factory('geocoder_wrapper', 60 * 60 * 24 * 10)

  Mapotempo::Application.config.router.url = 'http://router.beta.mapotempo.com/0.1'
  Mapotempo::Application.config.router.api_key = 'demo'
  # Mapotempo::Application.config.router.cache = cache_factory('router_wrapper', 60 * 60 * 24 * 10)

  Mapotempo::Application.config.optimizer.url = 'http://optimizer.beta.mapotempo.com/0.1'
  Mapotempo::Application.config.optimizer.api_key = 'demo'
  Mapotempo::Application.config.optimizer.cache = cache_factory('optimizer_wrapper', 60 * 60 * 24 * 10)

  Mapotempo::Application.config.devices.fleet.api_url = 'http://fleet.beta.mapotempo.com:8084'
  Mapotempo::Application.config.devices.fleet.admin_api_key = 'RcgPQutHr220KVQb6RQOPAtt'
end

debug = false ### EDIT THIS VALUE ### false | true | 'sql' | 'js' | 'n+1' | 'i18n'
if !debug || debug.is_a?(String)
  # Logger::INFO: (to deactive Logger::DEBUG / sql logs) http://guides.rubyonrails.org/debugging_rails_applications.html
  Rails.logger.level = Logger::INFO if debug != 'sql'

  Mapotempo::Application.config.assets.debug = false if debug != 'js'
  Mapotempo::Application.config.assets.logger = false if debug != 'js'
  Mapotempo::Application.config.action_view.raise_on_missing_translations = false if debug != 'i18n'
end

if defined? Bullet
  boolean = false
  Mapotempo::Application.config.after_initialize do
    Bullet.enable               = boolean
    Bullet.bullet_logger        = boolean
    Bullet.rails_logger         = boolean
    Bullet.counter_cache_enable = boolean
    Bullet.alert                = false
    Bullet.console              = false
    Bullet.add_footer           = false
  end
end

#
module Kernel
  def custom_inspector(msg)
    return unless Rails.env.development? || Rails.env.test?
    # ap "*** #{Time.zone.now} ***", color: {string: :green}
    ap msg.class if msg.respond_to?(:class)
    src = caller(1..1).first.gsub(Rails.root.to_s + '/', '')
    ap src, color: {string: :purpleish}
    ap msg
    ap '*** END ***', color: {string: :green}
  end
end

#
class ActiveSupport::Logger::SimpleFormatter
  SEVERITY_TO_TAG_MAP   = { 'DEBUG' => 'debug', 'INFO' => 'info', 'WARN' => 'warn', 'ERROR' => 'ERROR', 'FATAL' => 'FATAL', 'UNKNOWN' => 'UNKNOWN' }.freeze
  SEVERITY_TO_COLOR_MAP = { 'DEBUG' => '0;37', 'INFO' => '32', 'WARN' => '33', 'ERROR' => '31', 'FATAL' => '31', 'UNKNOWN' => '37' }.freeze
  USE_HUMOROUS_SEVERITIES = true
  def call(severity, time, _progname, msg)
    formatted_severity = if USE_HUMOROUS_SEVERITIES
      format('%-3s', SEVERITY_TO_TAG_MAP[severity])
    else
      format('%-5s', severity)
    end
    formatted_time = time.strftime('%Y-%m-%d %H:%M:%S.') << time.usec.to_s[0..2].rjust(3)
    color          = SEVERITY_TO_COLOR_MAP[severity]
    "\033[0;37m#{formatted_time}\033[0m [\033[#{color}m#{formatted_severity}\033[0m] #{msg.strip} (pid:#{$PID})\n"
  end
end
