# RISE — Piattaforma Competitiva per Artisti Musicali

**Bundle ID:** `com.dbosk.rise`

Piattaforma mensile dove artisti indipendenti competono con brani inediti.
Il pubblico vota, il vincitore porta a casa il montepremi reale.

---

## Setup

### 1. Prerequisiti

- Flutter SDK >= 3.0
- Firebase CLI
- Android Studio / Xcode
- Account RevenueCat
- Account AdMob

### 2. Clone & dipendenze

```bash
git clone <repo>
cd rise
flutter pub get
```

### 3. Firebase

1. Crea un progetto Firebase su [console.firebase.google.com](https://console.firebase.google.com)
2. Abilita: **Authentication** (Email/Password), **Firestore**, **Storage**, **Cloud Messaging**
3. Scarica `google-services.json` → `android/app/`
4. Scarica `GoogleService-Info.plist` → `ios/Runner/`
5. Aggiorna `FIREBASE_PROJECT_ID` in `.env`

#### Regole Firestore (copiare nella console)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Classifiche pubbliche
    match /brani_in_gara/{doc} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    match /gare/{doc} {
      allow read: if true;
      allow write: if request.auth.token.admin == true;
    }
    // Voti: solo utenti autenticati
    match /voti/{doc} {
      allow read: if request.auth != null && request.auth.uid == resource.data.ascoltatore_id;
      allow create: if request.auth != null;
    }
    // Utenti: solo il proprietario
    match /utenti/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // Artisti: lettura pubblica, scrittura solo owner
    match /artisti/{artistaId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == artistaId;
    }
  }
}
```

### 4. RevenueCat

1. Crea app su [app.revenuecat.com](https://app.revenuecat.com)
2. Configura prodotti in-app:
   - `rise_artista_monthly_599` → abbonamento 5,99€/mese
   - `rise_voti_extra_5_099` → one-time 0,99€
3. Copia API keys in `.env`:
   ```
   REVENUECAT_API_KEY_IOS=appl_xxx
   REVENUECAT_API_KEY_ANDROID=goog_xxx
   ```

### 5. AdMob

1. Crea app su [admob.google.com](https://admob.google.com)
2. Crea unità pubblicitarie: Banner (home, schermata brano), Interstitial
3. Aggiorna `.env` con tutti gli ID

### 6. Font (Google Fonts)

I font Oswald e Inter sono caricati via pacchetto `google_fonts` — nessuna configurazione extra.
Per uso offline aggiungi i file `.ttf` in `assets/fonts/`.

### 7. Android — Bundle ID

```
android/app/build.gradle → applicationId "com.dbosk.rise"
```

### 8. iOS — Bundle ID

```
Xcode → Targets → Runner → Bundle Identifier → com.dbosk.rise
```

### 9. Build

```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release
flutter build ios --release
```

---

## Architettura

```
lib/
  main.dart           # Entry point, Firebase + AdMob init
  theme/              # Colori, tipografia, temi
  models/             # Artista, Brano, Gara, Voto, Classifica, Premio
  services/           # Firebase, Auth, Gara, Voto, Storage, Pagamento
  providers/          # Auth, Gara, Voti, Theme (ChangeNotifier)
  router/             # GoRouter — tutte le route
  screens/            # Splash, Onboarding, Auth, Home, Gare, Artista, ...
  widgets/            # CountdownTimer, MontepremiCounter, VotaButton, ...
```

## Modello Economico

| Fonte | Importo | Destinazione |
|---|---|---|
| Abbonamento artista | 5,99€/mese | Piattaforma |
| Iscrizione brano | 2,00€ | 70% montepremi, 30% piattaforma |
| Voti extra | 0,99€ per 5 | Piattaforma |
| AdMob | CPC/CPM | Piattaforma |

## Regole di Gioco

- **5 voti gratuiti** a settimana per ogni utente registrato (reset ogni lunedì)
- **Max 1 voto** per brano per settimana (anti-bot)
- I brani devono essere **inediti** e restano in esclusiva RISE per **30 giorni** dopo la fine gara
- Fasi gara: Iscrizioni → Gironi → Quarti → Semifinale → **Finale**
