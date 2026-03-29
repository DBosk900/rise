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

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    _user = user;
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _isArtista = false;
      _artista = null;
      _utenteData = null;
    } else {
      _isArtista = await _authService.isArtista(user.uid);
      if (_isArtista) {
        final doc = await _db.collection('artisti').doc(user.uid).get();
        if (doc.exists) _artista = Artista.fromFirestore(doc);
      } else {
        _utenteData = await _authService.getUtenteData(user.uid);
      }
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
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
