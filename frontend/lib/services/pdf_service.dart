import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  /// Génère et télécharge/partage le dossier médical en PDF
  static Future<void> exporterDossierMedical({
    required BuildContext context,
    required Map<String, dynamic> dossier,
    required String nomPatient,
  }) async {
    final pdf = pw.Document();

    final patient = dossier['patient'] ?? {};
    final profil = dossier['profil_medical'] ?? {};
    final consultations = dossier['consultations'] as List? ?? [];
    final vaccinations = dossier['vaccinations'] as List? ?? [];

    // ── Couleurs et styles ─────────────────────────────────────────
    const colorPrimary = PdfColor.fromInt(0xFF1E88E5);
    const colorSuccess = PdfColor.fromInt(0xFF43A047);
    const colorSecondary = PdfColor.fromInt(0xFF546E7A);
    const colorBackground = PdfColor.fromInt(0xFFF5F9FF);

    final styleTitle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
      color: colorPrimary,
    );
    final styleHeading = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: colorPrimary,
    );
    final styleLabel = pw.TextStyle(
      fontSize: 10,
      color: colorSecondary,
    );
    final styleValue = pw.TextStyle(
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey900,
    );
    final styleNormal = pw.TextStyle(
      fontSize: 10,
      color: PdfColors.grey800,
    );

    // ── Helpers ────────────────────────────────────────────────────
    pw.Widget infoRow(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 130,
              child: pw.Text(label, style: styleLabel),
            ),
            pw.Expanded(
              child: pw.Text(value.isEmpty ? '—' : value, style: styleValue),
            ),
          ],
        ),
      );
    }

    pw.Widget sectionCard({
      required String title,
      required List<pw.Widget> children,
    }) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 16),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE3F2FD),
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(8),
                  topRight: pw.Radius.circular(8),
                ),
              ),
              child: pw.Text(title, style: styleHeading),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      );
    }

    // ── PAGE 1 : Identité & Profil médical ─────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LaafiBa', style: styleTitle),
                    pw.Text(
                      'Votre santé, notre priorité',
                      style: pw.TextStyle(fontSize: 10, color: colorSecondary),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'DOSSIER MÉDICAL',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: colorPrimary,
                      ),
                    ),
                    pw.Text(
                      'Généré le : ${_dateAujourdhui()}',
                      style: pw.TextStyle(fontSize: 9, color: colorSecondary),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: colorPrimary, thickness: 1.5),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('LaafiBa — Document confidentiel', style: pw.TextStyle(fontSize: 8, color: colorSecondary)),
            pw.Text('Page ${context.pageNumber} / ${context.pagesCount}', style: pw.TextStyle(fontSize: 8, color: colorSecondary)),
          ],
        ),
        build: (context) => [
          // Bannière patient
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            margin: const pw.EdgeInsets.only(bottom: 20),
            decoration: pw.BoxDecoration(
              color: colorPrimary,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 50,
                  height: 50,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      _initiales(
                        patient['prenom'] ?? '',
                        patient['nom'] ?? '',
                      ),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: colorPrimary,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${patient['prenom'] ?? ''} ${patient['nom'] ?? ''}'.trim(),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      patient['email'] ?? '',
                      style: pw.TextStyle(fontSize: 11, color: PdfColor.fromInt(0xCCFFFFFF)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Résumé médical rapide
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            margin: const pw.EdgeInsets.only(bottom: 20),
            decoration: pw.BoxDecoration(
              color: colorBackground,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColor.fromInt(0xFF1E88E5), width: 0.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _resumeItem('Groupe sanguin', profil['groupe_sanguin'] ?? '—', styleLabel, styleValue),
                _dividerV(),
                _resumeItem(
                  'Taille',
                  profil['taille'] != null ? '${profil['taille']} cm' : '—',
                  styleLabel,
                  styleValue,
                ),
                _dividerV(),
                _resumeItem(
                  'Poids',
                  profil['poids'] != null ? '${profil['poids']} kg' : '—',
                  styleLabel,
                  styleValue,
                ),
                _dividerV(),
                _resumeItem(
                  'Consultations',
                  '${consultations.length}',
                  styleLabel,
                  styleValue,
                ),
                _dividerV(),
                _resumeItem(
                  'Vaccinations',
                  '${vaccinations.length}',
                  styleLabel,
                  styleValue,
                ),
              ],
            ),
          ),

          // Section Identité
          sectionCard(
            title: 'Identité du patient',
            children: [
              infoRow('Nom complet', '${patient['prenom'] ?? ''} ${patient['nom'] ?? ''}'),
              infoRow('Email', patient['email'] ?? ''),
              infoRow('Téléphone', patient['telephone'] ?? ''),
              infoRow('Date de naissance', profil['date_naissance']?.toString() ?? ''),
              infoRow('Sexe', _labelSexe(profil['sexe'])),
              infoRow('Adresse', patient['adresse'] ?? ''),
              infoRow('N° Assurance', profil['numero_assurance'] ?? ''),
            ],
          ),

          // Section Profil médical
          sectionCard(
            title: 'Profil médical',
            children: [
              infoRow('Groupe sanguin', profil['groupe_sanguin'] ?? ''),
              infoRow('Taille', profil['taille'] != null ? '${profil['taille']} cm' : ''),
              infoRow('Poids', profil['poids'] != null ? '${profil['poids']} kg' : ''),
              infoRow('Allergies', profil['allergies'] ?? ''),
              infoRow('Antécédents', profil['antecedents'] ?? ''),
              infoRow('Médicaments actuels', profil['medicaments_actuels'] ?? ''),
              infoRow('Médecin traitant', profil['medecin_traitant'] ?? ''),
            ],
          ),

          // Section Consultations
          sectionCard(
            title: 'Historique des consultations (${consultations.length})',
            children: consultations.isEmpty
                ? [pw.Text('Aucune consultation enregistrée.', style: styleNormal)]
                : consultations.map((c) {
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 10),
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: colorBackground,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(
                          color: PdfColor.fromInt(0xFFE0E0E0),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                c['motif'] ?? '',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: colorPrimary,
                                ),
                              ),
                              pw.Text(
                                c['date_consultation']?.toString() ?? '',
                                style: pw.TextStyle(fontSize: 9, color: colorSecondary),
                              ),
                            ],
                          ),
                          if ((c['medecin_nom'] ?? '').isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            pw.Text('Médecin : ${c['medecin_nom']}', style: styleNormal),
                          ],
                          if ((c['diagnostic'] ?? '').isNotEmpty) ...[
                            pw.SizedBox(height: 3),
                            pw.Text('Diagnostic : ${c['diagnostic']}', style: styleNormal),
                          ],
                          if ((c['traitement'] ?? '').isNotEmpty) ...[
                            pw.SizedBox(height: 3),
                            pw.Text('Traitement : ${c['traitement']}', style: styleNormal),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
          ),

          // Section Vaccinations
          sectionCard(
            title: 'Vaccinations (${vaccinations.length})',
            children: vaccinations.isEmpty
                ? [pw.Text('Aucune vaccination enregistrée.', style: styleNormal)]
                : [
                    pw.Table(
                      border: pw.TableBorder.all(
                        color: PdfColor.fromInt(0xFFE0E0E0),
                        width: 0.5,
                      ),
                      children: [
                        // En-tête
                        pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFFE3F2FD),
                          ),
                          children: [
                            _cellule('Vaccin', styleHeading),
                            _cellule('Date', styleHeading),
                            _cellule('Statut', styleHeading),
                          ],
                        ),
                        // Lignes
                        ...vaccinations.map(
                          (v) => pw.TableRow(
                            children: [
                              _cellule(v['nom_vaccin'] ?? '', styleNormal),
                              _cellule(v['date_vaccination']?.toString() ?? '—', styleNormal),
                              _cellule(
                                v['statut'] == 'fait' ? 'Fait' : 'À faire',
                                pw.TextStyle(
                                  fontSize: 10,
                                  color: v['statut'] == 'fait' ? colorSuccess : PdfColors.orange,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
          ),

          // Signature / Cachet
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Document généré automatiquement',
                      style: pw.TextStyle(fontSize: 9, color: colorSecondary),
                    ),
                    pw.Text(
                      'LaafiBa — Plateforme de santé numérique',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: colorSecondary,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  _dateAujourdhui(),
                  style: pw.TextStyle(fontSize: 9, color: colorSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // ── Afficher le dialogue d'impression / partage ───────────────
    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'dossier_medical_${nomPatient.replaceAll(' ', '_')}.pdf',
    );
  }

  // ── Helpers privés ─────────────────────────────────────────────
  static String _dateAujourdhui() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  static String _initiales(String prenom, String nom) {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$p$n';
  }

  static String _labelSexe(dynamic sexe) {
    switch (sexe) {
      case 'M': return 'Masculin';
      case 'F': return 'Féminin';
      case 'autre': return 'Autre';
      default: return '—';
    }
  }

  static pw.Widget _resumeItem(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Column(
      children: [
        pw.Text(value, style: valueStyle),
        pw.SizedBox(height: 2),
        pw.Text(label, style: labelStyle),
      ],
    );
  }

  static pw.Widget _dividerV() {
    return pw.Container(
      width: 1,
      height: 30,
      color: PdfColor.fromInt(0xFFBBDEFB),
    );
  }

  static pw.Widget _cellule(String texte, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(texte, style: style),
    );
  }
}