import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SpeechScreen(),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Presiona el boton y comienza a hablar';
  double _confidence = 1.0;
  final translator = GoogleTranslator();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      if (available) {
        setState(() => _isListening = true);
        _startListening();
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _startListening() {
    _speech.listen(
      onResult: (val) async {
        String originalText = val.recognizedWords;
        String translatedText = await _translateText(originalText);
        setState(() {
          _text = translatedText;
          if (val.hasConfidenceRating && val.confidence > 0) {
            _confidence = val.confidence;
          }
        });
      },
      listenFor: Duration(seconds: 60),
      pauseFor: Duration(seconds: 5),
      partialResults: true,
      localeId: 'en_US',
    );
  }

  Future<String> _translateText(String text) async {
    try {
      var translation = await translator.translate(text, from: 'en', to: 'es');
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return 'Translation error';
    }
  }

  void _onStatus(String status) {
    print('onStatus: $status');
    if (status == 'notListening') {
      setState(() => _isListening = false);
    }
  }

  void _onError(dynamic error) {
    print('onError: $error');
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confidence: ${(_confidence * 100.0).toStringAsFixed(1)}%'),
      ),
      body: Center(
        child: Text(
          _text,
          style: TextStyle(fontSize: 32.0),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}
