require 'singleton'

class Thermostat
  
  include Singleton
  
  attr_reader :nest_api, :device_id, :structure_id, :user_id
  
  attr_accessor :previous_temperature
  
  def initialize
    load_api_connection!
  end
  
  def nest_id
    AUPAIR_CONFIG["nest"]["id"]
  end
  
  def status
    nest_api.status
  end
  
  def current_temperature
    nest_api.current_temperature.to_i
  end
  
  def target_temperature
    nest_api.temperature.to_i
  end
  
  def target_temperature=(_temp)
    nest_api.temperature=_temp
    load_api_connection!
    _temp
  end
  
  def public_ip
    nest_api.public_ip
  end

  def leaf
    nest_api.leaf
  end

  def humidity
    nest_api.humidity
  end
  
  def hvac_mode
    nest_api.hvac_mode
  end
  
  def away
    @away
  end
  
  def away_temperature
    case nest_api.status["device"][nest_id]["current_schedule_mode"]
    when "COOL"
      85
    when "HEAT"
      50
    end
  end
    
  def away=(_status=true)
    @away = _status
    
    if @away
      @previous_temperature = target_temperature
      self.target_temperature = away_temperature
    else
      self.target_temperature = @previous_temperature
    end
    load_api_connection!
    @away
  end  

  # status["device"]["09AA01AC36160LA1"]["fan_mode"]
  
  def hue_attributes    
    {
      current_temperature: current_temperature,
      target_temperature: target_temperature,
      hvac_mode: hvac_mode,
      public_ip: public_ip,
      leaf: leaf,
      humidity: humidity,
      away: away
    }
  end
  
  def to_json
    hue_attributes.to_json
  end
  
  private
  
  def load_api_connection!
    #'justin@justinrich.com' 'nXvyzqJtD54bEwT'
    @nest_api = NestThermostat::Nest.new(
      email: AUPAIR_CONFIG["nest"]["email"], 
      password: AUPAIR_CONFIG["nest"]["password"], 
      update_every: 900
    )   
    
    @user_id = nest_api.user_id
    @structure_id =  self.status['user'][user_id]['structures'][0].split('.')[1]
    @device_id = self.status['structure'][structure_id]['devices'][0].split('.')[1]
  end
  
end