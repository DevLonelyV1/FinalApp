enum WeatherCondition { sunny, cloudy, rainy }

class WeatherData {
  final double temperatureCelsius;
  final WeatherCondition condition;
  final double windSpeedKmh;
  final String
      cityName;

  WeatherData({
    required this.temperatureCelsius,
    required this.condition,
    required this.windSpeedKmh,
    required this.cityName,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {

    double windMps = (json['wind']['speed'] as num).toDouble();
    double windKmh = windMps * 3.6;


    String mainCondition = json['weather'][0]['main'];
    WeatherCondition appCondition;

    if (mainCondition == 'Clear') {
      appCondition = WeatherCondition.sunny;
    } else if (mainCondition == 'Clouds') {
      appCondition = WeatherCondition.cloudy;
    } else if (mainCondition == 'Rain' ||
        mainCondition == 'Drizzle' ||
        mainCondition == 'Thunderstorm') {
      appCondition = WeatherCondition.rainy;
    } else {
      appCondition =
          WeatherCondition.cloudy;
    }

    return WeatherData(
      temperatureCelsius: (json['main']['temp'] as num).toDouble(),
      condition: appCondition,
      windSpeedKmh: windKmh,
      cityName: json['name'],
    );
  }
}
