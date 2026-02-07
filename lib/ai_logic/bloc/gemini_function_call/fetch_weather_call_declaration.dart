import 'package:firebase_ai/firebase_ai.dart';

final fetchWeatherTool = FunctionDeclaration(
  'fetchWeather',
  'Get the weather conditions for a specific city on a specific date.',
  parameters: {
    'location': Schema.object(
      description:
          'The name of the city and its state for which to get'
          'the weather. Only cities in the USA are supported.',
      properties: {
        'city': Schema.string(description: 'The city of the location.'),
        'state': Schema.string(description: 'The US state of the location.'),
      },
    ),
    'date': Schema.string(
      description:
          'The date for which to get the weather. Date must be in the format: YYYY-MM-DD.',
    ),
  },
);
