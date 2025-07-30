import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() => runApp(PlacementApp());

class PlacementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Placement Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Color(0xFFF5F7FA),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6C63FF),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
      ),
      home: PlacementHomePage(),
    );
  }
}

class PlacementHomePage extends StatefulWidget {
  @override
  _PlacementHomePageState createState() => _PlacementHomePageState();
}

class _PlacementHomePageState extends State<PlacementHomePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _iqController = TextEditingController();
  final TextEditingController _cgpaController = TextEditingController();

  String? _result;
  bool _loading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  double _predictionConfidence = 0.0;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _iqController.dispose();
    _cgpaController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> getPlacementPrediction(double iq, double cgpa) async {
    // Use the correct URL for web
    final url = kIsWeb 
        ? Uri.parse('http://localhost:8000/predict/')
        : Uri.parse('http://10.0.2.2:8000/predict/');
    
    setState(() {
      _loading = true;
      _result = null;
      _predictionConfidence = 0.0;
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'iq': iq, 'cgpa': cgpa}),
      );

      print('Response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final placed = data['Placed'];
        
        // Handle different possible types from API
        bool isPlaced = (placed == 1) || 
                        (placed == true) || 
                        (placed.toString() == '1');
        
        setState(() {
          _result = isPlaced 
              ? "Placement Possible!" 
              : "Unlikely to be Placed";
          // For now we'll set a fixed confidence, you can update this if your API provides it
          _predictionConfidence = isPlaced ? 0.85 : 0.65;
        });
      } else {
        setState(() => _result = "API Error: ${response.statusCode}");
        _predictionConfidence = 0.0;
      }
    } catch (e) {
      setState(() => _result = "Connection Error: ${e.toString()}");
      _predictionConfidence = 0.0;
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Placement Predictor',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E2E3A),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Predict your chances of campus placement with our AI model',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _iqController,
                        decoration: InputDecoration(
                          labelText: 'IQ Score',
                          prefixIcon: Icon(Icons.psychology_outlined, color: Color(0xFF6C63FF)),
                          hintText: 'Enter your IQ score (0-200)',
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter IQ';
                          final iq = double.tryParse(value);
                          if (iq == null) return 'Enter valid number';
                          if (iq < 0 || iq > 200) return 'IQ must be between 0-200';
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _cgpaController,
                        decoration: InputDecoration(
                          labelText: 'CGPA',
                          prefixIcon: Icon(Icons.school_outlined, color: Color(0xFF6C63FF)),
                          hintText: 'Enter your CGPA (0-10)',
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter CGPA';
                          final cgpa = double.tryParse(value);
                          if (cgpa == null) return 'Enter valid number';
                          if (cgpa < 0 || cgpa > 10) return 'CGPA must be between 0-10';
                          return null;
                        },
                      ),
                      SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : () {
                            if (_formKey.currentState!.validate()) {
                              final iq = double.parse(_iqController.text.trim());
                              final cgpa = double.parse(_cgpaController.text.trim());
                              getPlacementPrediction(iq, cgpa);
                            }
                          },
                          icon: _loading 
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.analytics_outlined),
                          label: Text(_loading ? 'Predicting...' : 'Predict Placement'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultCard() {
    if (_result == null) return SizedBox.shrink();
    
    final isPositive = _result!.contains("Possible");
    final color = isPositive ? Color(0xFF4CAF50) : Color(0xFFF44336);
    
    return AnimatedOpacity(
      duration: Duration(milliseconds: 500),
      opacity: _result == null ? 0 : 1,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        margin: EdgeInsets.only(top: 30),
        padding: EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isPositive ? Icons.check_circle : Icons.warning,
                  color: color,
                  size: 32,
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    _result!,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            LinearProgressIndicator(
              value: _predictionConfidence,
              backgroundColor: color.withOpacity(0.2),
              color: color,
              minHeight: 12,
              borderRadius: BorderRadius.circular(10),
            ),
            SizedBox(height: 10),
            Text(
              'Confidence: ${(_predictionConfidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 15),
            Text(
              isPositive 
                ? 'Based on your IQ and CGPA, you have a strong chance of getting placed!'
                : 'Consider improving your skills and grades to increase placement opportunities.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      margin: EdgeInsets.only(top: 40),
      child: Text(
        'Powered by Sabya AI JhalEngine',
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              _buildHeader(),
              SizedBox(height: 40),
              _buildInputCard(),
              _buildResultCard(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }
}