require 'json'
require 'typhoeus'

account_id, username, password = ARGV

cookiefile = File.join(File.dirname(__FILE__), 'cookiefile')

response = Typhoeus.post(
  'https://mypages.verisure.com/j_spring_security_check?locale=sv_SE',
  body: {
    j_username: username,
    j_password: password,
  },
  cookiefile: cookiefile,
  cookiejar: cookiefile,
)

unless response.success?
  raise format('Could not sign in: %s', response.body)
end

response = Typhoeus.get(
  'https://mypages.verisure.com/overview/climatedevice',
  params: {
    _: account_id,
  },
  cookiefile: cookiefile,
  cookiejar: cookiefile,
)

unless response.success?
  raise format('Unknown error: %s', response.body)
end

MIN_TEMPERATURES_PER_LOCATION = {
  'Sovrum' => 20,
  'Vardagsrum' => 30,
  'Garage' => 30,
  'Entré' => 17,
}

too_cold_locations = {}
JSON.parse(response.body).each do |row|
  location = row['location']
  temperature = row['temperature'][/[^,]+/].to_i
  min_temperature = MIN_TEMPERATURES_PER_LOCATION.fetch(location) do
    raise format('No min temperature set for location: %s', location)
  end
  if temperature < min_temperature
    too_cold_locations[location] = [temperature, min_temperature]
  end
end

if too_cold_locations.empty?
  puts 'All rooms nice and warm'
else
  too_cold_locations.each do |location, temperatures|
    puts format('Location %s too cold %d (min %d)', location, *temperatures)
  end
end
