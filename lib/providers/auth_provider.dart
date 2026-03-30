import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/artista.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  AuthStatus _status = AuthStatus.loading;
  bool _isArtista = false;
  Artista? _artista;
  Map<String, dynamic>? _utenteData;
  String? _error;

  User? get user => _user;
  AuthStatus get status => _status;
  bool get isArtista => _isArtista;
  Artista? get artista => _artista;
  Map<String, dynamic>? get utenteData => _utenteData;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _init();
  }

  void _init() {
    debugPrint('AuthProvider: init');

    // Timeout di sicurezza: dopo 5s forza unauthenticated se ancora in loading
    Future.delayed(const Duration(seconds: 5), () {
      if (_status == AuthStatus.loading) {
        debugPrint('AuthProvider: timeout - forcing unauthenticated');
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });

    try {
      _authService.authStateChanges.listen(
        _onAuthChanged,
        onError: (e) {
          debugPrint('AuthProvider: authStateChanges error: $e');
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('AuthProvider: failed to start auth listener: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _onAuthChanged(User? user) async {
    debugPrint('AuthProvider: auth changed, user=${user?.uid}');
    _user = user;
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _isArtista = false;
      _artista = null;
      _utenteData = null;
      notifyListeners();
      return;
    }

    try {
      _isArtista = await _authService.isArtista(user.uid);
      if (_isArtista) {
        final doc = await _db.collection('artisti').doc(user.uid).get();
        if (doc.exists) _artista = Artista.fromFirestore(doc);
      } else {
        _utenteData = await _authService.getUtenteData(user.uid);
      }
    } catch (e) {
      debugPrint('AuthProvider: error loading user data: $e');
    }

    _status = AuthStatus.authenticated;
    notifyListeners();
    debugPrint('AuthProvider: status = authenticated');
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _error = null;
      await _authService.signInWithEmail(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String nome,
    required bool isArtista,
  }) async {
    try {
      _error = null;
      await _authService.registerWithEmail(
        email: email,
        password: password,
        nome: nome,
        isArtista: isArtista,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> refreshArtista() async {
    if (_user == null || !_isArtista) return;
    final doc = await _db.collection('artisti').doc(_user!.uid).get();
    if (doc.exists) {
      _artista = Artista.fromFirestore(doc);
      notifyListeners();
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nessun account trovato con questa email';
      case 'wrong-password':
        return 'Password non corretta';
      case 'email-already-in-use':
        return 'Email già registrata';
      case 'weak-password':
        return 'Password troppo debole (min. 6 caratteri)';
      case 'invalid-email':
        return 'Indirizzo email non valido';
      case 'too-many-requests':
        return 'Troppi tentativi. Riprova tra qualche minuto';
      default:
        return 'Errore di autenticazione. Riprova';
    }
  }
}
