import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../repository/location_repository.dart';
import '../services/weather_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final weatherService = WeatherService();
  final locationRepository = LocationRepository();

  final Map<String, List<String>> stateCities = {
    'SP': ['São Paulo', 'Campinas', 'Santos'],
    'RJ': ['Rio de Janeiro', 'Niterói', 'Cabo Frio'],
    'MG': ['Belo Horizonte', 'Uberlândia', 'Ouro Preto'],
    'BA': ['Salvador', 'Feira de Santana', 'Porto Seguro'],
  };

  String? selectedState;
  String? selectedCity;
  Weather? weather;
  String? savedLocation;
  bool loading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
  }

  Future<void> _loadSavedLocation() async {
    final lastLocation = await locationRepository.loadLastLocation();
    if (lastLocation != null && mounted) {
      setState(() {
        savedLocation = lastLocation;
      });
      await _searchWeather(lastLocation);
    }
  }

  Future<void> _searchWeather(String location) async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    final parts = location.split(',');
    final city = parts.first.trim();
    final state = parts.length > 1 ? parts[1].trim() : null;

    final result = await weatherService.fetchWeatherByCity(city, state: state);
    if (!mounted) return;

    setState(() {
      loading = false;
      if (result != null) {
        weather = result;
        savedLocation = location;
        locationRepository.saveLocation(location);
      } else {
        errorMessage = 'Não foi possível buscar a previsão. Verifique o nome da cidade.';
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<String> get allCities {
    return stateCities.values.expand((cities) => cities).toSet().toList();
  }

  List<String> get citiesForSelectedState {
    if (selectedState == null) {
      return allCities;
    }
    return stateCities[selectedState!] ?? [];
  }

  Widget _buildWeatherCard() {
    if (weather == null) {
      return const SizedBox();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${weather!.city}, ${weather!.country}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Condição: ${weather!.description}'),
            const SizedBox(height: 8),
            Text('Temperatura atual: ${weather!.temperature.toStringAsFixed(1)} °C'),
            Text('Mínima: ${weather!.minTemperature.toStringAsFixed(1)} °C'),
            Text('Máxima: ${weather!.maxTemperature.toStringAsFixed(1)} °C'),
            const SizedBox(height: 8),
            Text('Humidade: ${weather!.humidity}%'),
            Text('Velocidade do vento: ${weather!.windSpeed.toStringAsFixed(1)} m/s'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previsão do Tempo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (savedLocation != null)
              Text('Última localização salva: $savedLocation'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              value: selectedState,
              items: [null, ...stateCities.keys].map((state) {
                return DropdownMenuItem<String>(
                  value: state,
                  child: Text(state == null ? 'Todos os estados' : state),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedState = value;
                  selectedCity = null;
                });
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Cidade',
                border: OutlineInputBorder(),
              ),
              value: selectedCity,
              items: [null, ...citiesForSelectedState].map((city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city == null ? 'Todas as cidades' : city),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCity = value;
                });
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () {
                      if (selectedCity == null && selectedState == null) {
                        setState(() {
                          errorMessage = 'Escolha um estado e/ou cidade.';
                        });
                        return;
                      }
                      final location = selectedCity ?? selectedState!;
                      _searchWeather(location);
                    },
              child: const Text('Buscar clima'),
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            _buildWeatherCard(),
          ],
        ),
      ),
    );
  }
}
