import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

const API_URL = 'https://xneo-web.onrender.com';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider(String? initialToken) {
    if (initialToken != null) {
      _token = initialToken;
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    try {
      final response = await http.get(
        Uri.parse('$API_URL/api/auth/me'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = User.fromJson(data);
        notifyListeners();
      } else {
        await _clearSession();
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$API_URL/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username.trim(),
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _user = User.fromJson(data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Credenciales incorrectas';
      }
    } catch (e) {
      _error = 'Error de conexión. Verifica tu internet.';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$API_URL/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username.trim(),
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _token = data['token'];
        _user = User.fromJson(data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Error al crear cuenta';
      }
    } catch (e) {
      _error = 'Error de conexión. Verifica tu internet.';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> updateProfile({String? username, String? info, String? category}) async {
    try {
      final response = await http.put(
        Uri.parse('$API_URL/api/auth/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          if (username != null) 'username': username,
          if (info != null) 'info': info,
          if (category != null) 'category': category,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = User.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
    _user = null;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$API_URL/api/auth/logout'),
        headers: {'Authorization': 'Bearer $_token'},
      );
    } catch (e) {}
    
    await _clearSession();
  }
}
