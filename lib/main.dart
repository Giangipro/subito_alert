import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inizializza Firebase (richiede il file google-services.json inserito in android/app/)
  await Firebase.initializeApp();
  runApp(const SubitoAlertApp());
}

class SubitoAlertApp extends StatelessWidget {
  const SubitoAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subito Alert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Schema colori ispirato alla tavolozza dinamica pastello dei Google Pixel
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8), // Blu Google
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system, // Segue automaticamente il tema del tuo S23 Ultra
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _queryController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;

  // Riferimento al documento condiviso con l'iPhone 6s
  final DocumentReference _databaseRef = FirebaseFirestore.instance
      .collection('ricerche')
      .doc('ricerca_attiva');

  @override
  void dispose() {
    _queryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Aggiorna i parametri di ricerca nel Cloud. L'iPhone leggerà questi dati al prossimo avvio.
  Future<void> _aggiornaRicerca() async {
    if (_queryController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci una ricerca e un prezzo validi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _databaseRef.update({
        'query': _queryController.text.trim(),
        'prezzo_massimo': int.parse(_priceController.text.trim()),
        'nuovo_annuncio_rilevato': false, // Resetta lo stato di notifica
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ricerca aggiornata! L\'iPhone si sta già allineando.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il salvataggio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Subito Alert",
          style: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'GoogleSans'),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _databaseRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Nessuna configurazione trovata nel database."),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final queryAttiva = data['query'] ?? 'Nessuna';
          final prezzoMassimo = data['prezzo_massimo'] ?? 0;
          final nuovoAnnuncio = data['nuovo_annuncio_rilevato'] ?? false;
          final ultimoTitolo = data['ultimo_titolo'] ?? '';
          final ultimoPrezzo = data['ultimo_prezzo'] ?? 0;
          final ultimoLink = data['ultimo_link'] ?? '';

          // Popola i campi di testo con i valori correnti la prima volta
          if (_queryController.text.isEmpty && _priceController.text.isEmpty) {
            _queryController.text = queryAttiva;
            _priceController.text = prezzoMassimo.toString();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // CARD 1: Stato e Ricerca Attiva (Stile Pixel)
                Card(
                  elevation: 0,
                  color: nuevoAnnuncio 
                      ? colorScheme.primaryContainer 
                      : colorScheme.secondaryContainer.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              nuevoAnnuncio ? Icons.notification_important : Icons.search,
                              color: nuevoAnnuncio ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              nuevoAnnuncio ? "Nuovo Annuncio Trovato!" : "Monitoraggio Attivo",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: nuevoAnnuncio ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          queryAttiva,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: nuevoAnnuncio ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          "Prezzo massimo impostato: $prezzoMassimo €",
                          style: TextStyle(
                            fontSize: 16,
                            color: nuevoAnnuncio 
                                ? colorScheme.onPrimaryContainer.withOpacity(0.8) 
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // CARD 2: Ultimo annuncio rilevato dall'iPhone 6s
                if (nuevoAnnuncio && ultimoTitolo.isNotEmpty) ...[
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dettagli Offerta",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ultimoTitolo,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$ultimoPrezzo €",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () {
                              // Reimposta lo stato su letto
                              _databaseRef.update({'nuovo_annuncio_rilevato': false});
                            },
                            icon: const Icon(Icons.check),
                            label: const Text("Segna come letto"),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // CARD 3: Modifica Ricerca (Input Fields)
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Modifica Parametri",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _queryController,
                          decoration: InputDecoration(
                            labelText: "Cosa cercare su Subito?",
                            filled: true,
                            fillColor: colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Prezzo Massimo (€)",
                            filled: true,
                            fillColor: colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : FilledButton(
                                onPressed: _aggiornaRicerca,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text("Invia all'iPhone 6s"),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
