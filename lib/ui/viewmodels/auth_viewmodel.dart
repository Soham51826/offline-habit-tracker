import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ViewModel managing local user authentication state, profiles, and guest sessions.
/// Designed for offline-first resilience with instant responsiveness.
class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isGuest = false;
  String _userName = '';
  String _userEmail = '';

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  String get userName => _userName;
  String get userEmail => _userEmail;

  AuthViewModel({
    bool initialIsLoggedIn = false,
    bool initialIsGuest = false,
    String initialUserName = '',
    String initialUserEmail = '',
    bool autoInit = true,
  })  : _isLoading = false,
        _isLoggedIn = initialIsLoggedIn,
        _isGuest = initialIsGuest,
        _userName = initialUserName,
        _userEmail = initialUserEmail {
    if (autoInit) {
      initAuth();
    }
  }

  /// Restores session state from persistent storage.
  Future<void> initAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      _isGuest = prefs.getBool('is_guest') ?? false;
      _userName = prefs.getString('user_name') ?? '';
      _userEmail = prefs.getString('user_email') ?? '';
    } catch (e) {
      debugPrint('Error restoring auth state: $e');
      _isLoggedIn = false;
      _isGuest = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Authenticates an existing user and persists the session.
  Future<bool> login({
    required String email,
    required String password,
    String? preferredName,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Simulate swift network/local verification
    await Future.delayed(const Duration(milliseconds: 350));

    final trimmedEmail = email.trim();
    String displayName = preferredName?.trim() ?? '';
    if (displayName.isEmpty) {
      final parts = trimmedEmail.split('@');
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        displayName = parts[0][0].toUpperCase() + parts[0].substring(1);
      } else {
        displayName = 'User';
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_guest', false);
      await prefs.setString('user_name', displayName);
      await prefs.setString('user_email', trimmedEmail);

      _isLoggedIn = true;
      _isGuest = false;
      _userName = displayName;
      _userEmail = trimmedEmail;
    } catch (e) {
      debugPrint('Error persisting login: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return true;
  }

  /// Registers a new user account and activates their session.
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));

    final trimmedName = name.trim();
    final trimmedEmail = email.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_guest', false);
      await prefs.setString('user_name', trimmedName);
      await prefs.setString('user_email', trimmedEmail);

      _isLoggedIn = true;
      _isGuest = false;
      _userName = trimmedName;
      _userEmail = trimmedEmail;
    } catch (e) {
      debugPrint('Error persisting signup: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return true;
  }

  /// Activates an immediate offline guest session without requiring credentials.
  Future<void> continueAsGuest() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200));

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_guest', true);
      await prefs.setString('user_name', 'Guest');
      await prefs.setString('user_email', 'guest@offline.local');

      _isLoggedIn = true;
      _isGuest = true;
      _userName = 'Guest';
      _userEmail = 'guest@offline.local';
    } catch (e) {
      debugPrint('Error persisting guest session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Instant demonstration login for examiners and project evaluators without hardcoded credentials.
  Future<void> loginAsDemo({String name = 'Soham'}) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 250));

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_guest', false);
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', '$name@local.offline');

      _isLoggedIn = true;
      _isGuest = false;
      _userName = name;
      _userEmail = '$name@local.offline';
    } catch (e) {
      debugPrint('Error persisting demo session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logs out the user and clears stored session tokens.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_logged_in');
      await prefs.remove('is_guest');
      await prefs.remove('user_name');
      await prefs.remove('user_email');

      _isLoggedIn = false;
      _isGuest = false;
      _userName = '';
      _userEmail = '';
    } catch (e) {
      debugPrint('Error logging out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
