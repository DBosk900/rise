import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gara_provider.dart';
import '../../services/storage_service.dart';
import '../../services/gara_service.dart';
import '../../theme/app_theme.dart';
import 'dashboard_artista_screen.dart';
import 'package:google_fonts/google_fonts.dart';

const _generi = [
  'Pop', 'Rock', 'Hip Hop', 'R&B', 'Electronic',
  'Jazz', 'Classica', 'Folk', 'Indie', 'Metal',
  'Reggaeton', 'Latina', 'Country', 'Blues', 'Soul',
];

class UploadBranoScreen extends StatefulWidget {
  const UploadBranoScreen({super.key});

  @override
  State<UploadBranoScreen> createState() => _UploadBranoScreenState();
}

class _UploadBranoScreenState extends State<UploadBranoScreen> {
  int _step = 0;
  File? _audioFile;
  File? _coverFile;
  final _titoloCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String? _genere;
  double _audioProgress = 0;
  double _coverProgress = 0;
  bool _uploading = false;

  final _storage = StorageService();
  final _garaService = GaraService();

  @override
  void dispose() {
    _titoloCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final valid = await _storage.validateAudioFile(file);
      if (!valid) {
        _showError('File audio troppo grande (max 20MB)');
        return;
      }
      setState(() => _audioFile = file);
    }
  }

  Future<void> _pickCover() async {
    final result = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    if (result != null) {
      final file = File(result.path);
      final valid = await _storage.validateImageFile(file);
      if (!valid) {
        _showError('Immagine troppo grande (max 5MB)');
        return;
      }
      setState(() => _coverFile = file);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
    );
  }

  bool get _stepValid {
    switch (_step) {
      case 0:
        return _audioFile != null;
      case 1:
        return _coverFile != null;
      case 2:
        return _bioCtrl.text.trim().isNotEmpty;
      case 3:
        return _genere != null;
      default:
        return true;
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final gara = context.read<GaraProvider>();

    if (auth.user == null || gara.garaAttiva == null) return;
    if (_audioFile == null || _coverFile == null || _genere == null) return;

    setState(() => _uploading = true);

    try {
      // Upload audio
      final urlAudio = await _storage.uploadAudio(
        file: _audioFile!,
        artistaId: auth.user!.uid,
        garaId: gara.garaAttiva!.id,
        onProgress: (p) => setState(() => _audioProgress = p),
      );

      // Upload cover
      final urlCover = await _storage.uploadCover(
        file: _coverFile!,
        artistaId: auth.user!.uid,
        garaId: gara.garaAttiva!.id,
        onProgress: (p) => setState(() => _coverProgress = p),
      );

      // Iscrivi brano
      await _garaService.iscriviBrano(
        garaId: gara.garaAttiva!.id,
        artistaId: auth.user!.uid,
        artistaNome: auth.artista?.nome ?? auth.user!.displayName ?? 'Artista',
        titolo: _titoloCtrl.text.trim(),
        urlAudio: urlAudio,
        urlCover: urlCover,
        bio: _bioCtrl.text.trim(),
        genere: _genere!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Brano iscritto con successo!'),
          backgroundColor: AppColors.rankUp,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardArtistaScreen()),
      );
    } catch (e) {
      if (mounted) _showError('Errore: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Iscrivi Brano — Step ${_step + 1}/5'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Progress stepper
          _Stepper(step: _step),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStep(),
            ),
          ),

          // Bottone avanti
          if (!_uploading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: GestureDetector(
                  onTap: _stepValid
                      ? () {
                          if (_step < 4) {
                            setState(() => _step++);
                          } else {
                            _submit();
                          }
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: _stepValid
                          ? AppColors.primaryGradient
                          : const LinearGradient(
                              colors: [Color(0xFF444444), Color(0xFF555555)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _step < 4 ? 'AVANTI' : 'CONFERMA E PAGA 2€',
                        style: GoogleFonts.oswald(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (_audioProgress + _coverProgress) / 2,
                    backgroundColor: AppColors.cardDark,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text('Caricamento in corso...',
                      style: AppTextStyles.bodySmall(context)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _StepAudio(
          file: _audioFile,
          onPick: _pickAudio,
        );
      case 1:
        return _StepCover(
          file: _coverFile,
          onPick: _pickCover,
        );
      case 2:
        return _StepBio(titoloCtrl: _titoloCtrl, bioCtrl: _bioCtrl);
      case 3:
        return _StepGenere(
          genereSelezionato: _genere,
          onSelect: (g) => setState(() => _genere = g),
        );
      case 4:
        return _StepConferma(
          titolo: _titoloCtrl.text,
          genere: _genere ?? '',
          audioName: _audioFile?.path.split('/').last ?? '',
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _Stepper extends StatelessWidget {
  final int step;
  const _Stepper({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(5, (i) {
          final done = i < step;
          final active = i == step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: done || active ? AppColors.primaryGradient : null,
                      color: done || active ? null : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < 4) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StepAudio extends StatelessWidget {
  final File? file;
  final VoidCallback onPick;
  const _StepAudio({this.file, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('🎵', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 16),
        Text('Carica il file audio', style: AppTextStyles.headline3(context)),
        const SizedBox(height: 8),
        Text('Formati: MP3, WAV, M4A — Max 20MB',
            style: AppTextStyles.bodyMedium(context)),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: onPick,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: file != null
                    ? AppColors.rankUp
                    : AppColors.textDim.withValues(alpha: 0.4),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  file != null ? Icons.check_circle : Icons.upload_file,
                  size: 40,
                  color: file != null ? AppColors.rankUp : AppColors.textDim,
                ),
                const SizedBox(height: 8),
                Text(
                  file != null
                      ? file!.path.split('/').last
                      : 'Tocca per caricare',
                  style: AppTextStyles.bodyMedium(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepCover extends StatelessWidget {
  final File? file;
  final VoidCallback onPick;
  const _StepCover({this.file, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('🖼️', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 16),
        Text('Carica la cover art', style: AppTextStyles.headline3(context)),
        const SizedBox(height: 8),
        Text('Immagine quadrata, min 500×500px',
            style: AppTextStyles.bodyMedium(context)),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: onPick,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: file != null ? AppColors.rankUp : AppColors.textDim.withValues(alpha: 0.4),
              ),
              image: file != null
                  ? DecorationImage(
                      image: FileImage(file!), fit: BoxFit.cover)
                  : null,
            ),
            child: file == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate,
                          size: 48, color: AppColors.textDim),
                      const SizedBox(height: 8),
                      Text('Carica immagine',
                          style: AppTextStyles.bodySmall(context)),
                    ],
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _StepBio extends StatelessWidget {
  final TextEditingController titoloCtrl;
  final TextEditingController bioCtrl;
  const _StepBio({required this.titoloCtrl, required this.bioCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('✍️', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 16),
        Text('Info brano e bio', style: AppTextStyles.headline3(context)),
        const SizedBox(height: 32),
        TextField(
          controller: titoloCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Titolo brano'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: bioCtrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 4,
          maxLength: 300,
          decoration: const InputDecoration(
            labelText: 'Bio artista (max 300 caratteri)',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

class _StepGenere extends StatelessWidget {
  final String? genereSelezionato;
  final void Function(String) onSelect;
  const _StepGenere({this.genereSelezionato, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🎸', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 16),
        Text('Seleziona il genere', style: AppTextStyles.headline3(context)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _generi.map((g) {
            final sel = g == genereSelezionato;
            return GestureDetector(
              onTap: () => onSelect(g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: sel ? AppColors.primaryGradient : null,
                  color: sel ? null : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: sel
                        ? Colors.transparent
                        : AppColors.textDim.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  g,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color:
                        sel ? Colors.white : AppColors.textSecondary,
                    fontWeight:
                        sel ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StepConferma extends StatelessWidget {
  final String titolo;
  final String genere;
  final String audioName;
  const _StepConferma(
      {required this.titolo, required this.genere, required this.audioName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('✅', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 16),
        Text('Conferma iscrizione', style: AppTextStyles.headline3(context)),
        const SizedBox(height: 8),
        Text('Controlla i dettagli prima di pagare',
            style: AppTextStyles.bodyMedium(context)),
        const SizedBox(height: 32),
        _Row(label: 'Titolo', value: titolo),
        _Row(label: 'Genere', value: genere),
        _Row(label: 'Audio', value: audioName),
        const Divider(color: AppColors.cardDark, height: 32),
        _Row(
            label: 'Quota iscrizione',
            value: '2,00€',
            highlight: true),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
          ),
          child: Text(
            '⚠️ Il brano deve essere inedito e resterà in esclusiva su RISE per 30 giorni dalla fine della gara.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.gold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _Row({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium(context)),
          Text(
            value,
            style: highlight
                ? GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold)
                : AppTextStyles.labelBold(context),
          ),
        ],
      ),
    );
  }
}
