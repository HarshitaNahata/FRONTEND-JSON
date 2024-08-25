import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your Roll Number',
      home: JsonProcessor(),
    );
  }
}

class JsonProcessor extends StatefulWidget {
  @override
  _JsonProcessorState createState() => _JsonProcessorState();
}

class _JsonProcessorState extends State<JsonProcessor> {
  final TextEditingController _jsonController = TextEditingController();
  final List<String> _selectedOptions = [];
  Map<String, dynamic>? _response;
  String? _error;

  bool _isValidJson(String input) {
    try {
      jsonDecode(input);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _submitJson() async {
    final input = _jsonController.text.trim();
    
    if (!_isValidJson(input)) {
      setState(() {
        _error = 'Invalid JSON format';
        _response = null;
      });
      return;
    }

    try {
      final parsedInput = jsonDecode(input);
      final response = await http.post(
        Uri.parse('https://your-project-id.cloudfunctions.net/bfhl'), // replace with your actual endpoint
        body: jsonEncode(parsedInput),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _response = jsonDecode(response.body);
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Server error';
          _response = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Unexpected error occurred: $e';
        _response = null;
      });
    }
  }

  Widget _buildResponse() {
    if (_response == null) return Container();
    
    List<String> filteredResponse = [];
    if (_selectedOptions.contains('Alphabets')) {
      filteredResponse.addAll(List<String>.from(_response!['alphabets']));
    }
    if (_selectedOptions.contains('Numbers')) {
      filteredResponse.addAll(List<String>.from(_response!['numbers']));
    }
    if (_selectedOptions.contains('Highest lowercase alphabet')) {
      filteredResponse
          .addAll(List<String>.from(_response!['highest_lowercase_alphabet']));
    }
    return Text(filteredResponse.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Roll Number')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _jsonController,
              decoration: InputDecoration(
                labelText: 'Enter JSON',
                errorText: _error,
              ),
            ),
            ElevatedButton(onPressed: _submitJson, child: Text('Submit')),
            if (_response != null) ...[
              DropdownButtonFormField<String>(
                hint: Text('Select options'),
                items: [
                  'Alphabets',
                  'Numbers',
                  'Highest lowercase alphabet',
                ]
                    .map((option) =>
                        DropdownMenuItem(value: option, child: Text(option)))
                    .toList(),
                onChanged: (value) {
                  if (value != null && !_selectedOptions.contains(value)) {
                    setState(() {
                      _selectedOptions.add(value);
                    });
                  }
                },
              ),
              SizedBox(height: 20),
              _buildResponse(),
            ],
          ],
        ),
      ),
    );
  }
}
