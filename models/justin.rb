require 'singleton'
require 'json'
require 'mongo'
require 'tzinfo'

class Justin
  
  include Singleton
  
  attr_reader :house, :location, :locations
  
  def initialize
    @db_locations = DATABASE[:locations]
    
    @house = House.instance
    update_location(@house.location.lat, @house.location.lng)
  end

  def update_location(_lat,_lng)    
    # If you're not updating the location, don't bother
    return nil if !@location.nil? && @location.lat == _lat && @location.lng == _lng
    
    if !@location.nil?
      @db_locations.insert({
        time: Time.now.utc.to_i, 
        lat: _lat, 
        lng: _lng
      })
    end
        
    previously = outside_geofence    
            
    # Create the new location
    @location = Geokit::LatLng.new(_lat,_lng) 
    
    # Set @outside_geofence to nil, so next time instance function outside_geofence is called, the
    # distance from home will be re-calculated and cached
    @outside_geofence = nil
        
    # If there is a change in at-home or away status after the new coordinates
    if previously.nil? || (previously != outside_geofence)
      self.away=outside_geofence
    end
  end
  
  def locations
    @locations = []
    @db_locations.find.each do |location|
      @locations << location
    end
    @locations
  end
  
  def locations_for_day(time = Time.now)    
    @db_locations.find({
      "time" => {
        "$gte" => timezone.utc_to_local(time.beginning_of_day).to_i, 
        "$lte" => timezone.utc_to_local(time.end_of_day).to_i
      }
    })    
  end
  
  def outside_geofence
    @outside_geofence ||= calc_outside_geofence
  end
  
  def calc_outside_geofence
    return nil if @location.nil?
     distance_from_home >= 0.5
  end
  
  def distance_from_home
    @location.distance_to(@house.location)
  end
  
  def away
    @away ||= calc_outside_geofence
  end
  
  def lat
    @location.lat
  end
  
  def lng
    @location.lng
  end
  
  def timezone
    @timezone ||=  TZInfo::Timezone.get('America/New_York')
  end
  
  def away=(_status)
    @away = _status
    @away ? @house.set_away : @house.set_home      
    self
  end
  
  def to_json
    {
      location: [lat, lng],
      outside:   outside_geofence,
      away:      away
    }.to_json
  end
  
end
