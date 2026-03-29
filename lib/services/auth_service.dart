import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artista.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String nome,
    required bool isArtista,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(nome);

    if (isArtista) {
      final artista = Artista(
        id: cred.user!.uid,
        nome: nome,
        email: email,
        abbonamentoAttivo: false,
        createdAt: DateTime.now(),
      );
      await _db
          .collection('artisti')
          .doc(cred.user!.uid)
          .set(artista.toFirestore());
    } else {
      await _db.collection('utenti').doc(cred.user!.uid).set({
        'nome': nome,
        'email': email,
        'ruolo': 'ascoltatore',
        'voti_gratuiti_rimasti': 5,
        'voti_extra_disponibili': 0,
        'settimana_reset': _prossimoLunedi().toIso8601String(),
        'created_at': Timestamp.now(),
      });
    }

    return cred;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<Map<String, dynamic>?> getUtenteData(String uid) async {
    final doc = await _db.collection('utenti').doc(uid).get();
    if (doc.exists) return doc.data();
    final artistaDoc = await _db.collection('artisti').doc(uid).get();
    if (artistaDoc.exists) return artistaDoc.data();
    return null;
  }

  Future<bool> isArtista(String uid) async {
    final doc = await _db.collection('artisti').doc(uid).get();
    return doc.exists;
  }

  DateTime _prossimoLunedi() {
    final now = DateTime.now();
    final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    return DateTime(now.year, now.month, now.day + daysUntilMonday);
  }
}
