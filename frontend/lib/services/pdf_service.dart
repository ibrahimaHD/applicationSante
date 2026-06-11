import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';

class PdfService {
  static Future<void> exporterDossierMedical({
    required BuildContext context,
    required UserModel user,
    required Map<String, dynamic> dossier,
  }) async {
    final pdf = pw.Document();

    final patient   = dossier['patient']       ?? {};
    final profil    = dossier['profil_medical'] ?? {};
    final consults  = (dossier['consultations'] as List?) ?? [];
    final vaccins   = (dossier['vaccinations']  as List?) ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.teal700, width: 2),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('LaafiBa',
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal700)),
                  pw.Text('Dossier médical',
                      style: pw.TextStyle(
                          fontSize: 13,
                          color: PdfColors.grey700)),
                ],
              ),
              pw.Text(
                'Généré le ${_formatDate(DateTime.now().toString())}',
                style: pw.TextStyle(
                    fontSize: 11, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        footer: (_) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300),
            ),
          ),
          child: pw.Center(
            child: pw.Text(
              'Document confidentiel — LaafiBa © ${DateTime.now().year}',
              style: pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey500),
            ),
          ),
        ),
        build: (_) => [
          // ── Identité ──────────────────────────────────
          _section('Identité du patient', PdfColors.teal700),
          _infoGrid([
            ['Nom complet', '${patient['prenom'] ?? ''} ${patient['nom'] ?? ''}'],
            ['Email',       patient['email']     ?? '--'],
            ['Téléphone',   patient['telephone'] ?? '--'],
            ['Groupe sanguin', profil['groupe_sanguin'] ?? '--'],
            ['Date de naissance', _formatDate(profil['date_naissance']?.toString() ?? '')],
            ['Sexe',        profil['sexe'] ?? '--'],
          ]),

          pw.SizedBox(height: 16),

          // ── Informations médicales ─────────────────────
          _section('Informations médicales', PdfColors.blue700),
          _infoGrid([
            ['Taille',    profil['taille'] != null ? '${profil['taille']} cm' : '--'],
            ['Poids',     profil['poids']  != null ? '${profil['poids']} kg'  : '--'],
            ['Allergies', profil['allergies'] ?? '--'],
            ['Antécédents', profil['antecedents'] ?? '--'],
            ['Traitements actuels', profil['medicaments_actuels'] ?? '--'],
            ['Médecin traitant',    profil['medecin_traitant']    ?? '--'],
          ]),

          pw.SizedBox(height: 16),

          // ── Consultations ─────────────────────────────
          if (consults.isNotEmpty) ...[
            _section('Consultations (${consults.length})', PdfColors.purple700),
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // En-tête
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                      color: PdfColors.purple50),
                  children: ['Motif', 'Diagnostic', 'Traitement', 'Date']
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(h,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10)),
                          ))
                      .toList(),
                ),
                // Lignes
                ...consults.map((c) => pw.TableRow(
                  children: [
                    c['motif']      ?? '--',
                    c['diagnostic'] ?? '--',
                    c['traitement'] ?? '--',
                    _formatDate(c['date_consultation']?.toString() ?? ''),
                  ]
                      .map((v) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(v.toString(),
                                style: const pw.TextStyle(fontSize: 9)),
                          ))
                      .toList(),
                )),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // ── Vaccinations ──────────────────────────────
          if (vaccins.isNotEmpty) ...[
            _section('Vaccinations (${vaccins.length})', PdfColors.green700),
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                      color: PdfColors.green50),
                  children: ['Vaccin', 'Date', 'Statut']
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(h,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10)),
                          ))
                      .toList(),
                ),
                ...vaccins.map((v) => pw.TableRow(
                  children: [
                    v['nom_vaccin'] ?? '--',
                    _formatDate(v['date_vaccination']?.toString() ?? ''),
                    v['statut'] == 'fait' ? 'Effectué' : 'À faire',
                  ]
                      .map((val) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(val.toString(),
                                style: const pw.TextStyle(fontSize: 9)),
                          ))
                      .toList(),
                )),
              ],
            ),
          ],
        ],
      ),
    );

    // ✅ Afficher l'aperçu + option téléchargement/partage
    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'dossier_${patient['nom'] ?? 'patient'}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // ── Helpers ────────────────────────────────────────────
  static pw.Widget _section(String titre, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(titre,
          style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _infoGrid(List<List<String>> data) {
    return pw.GridView(
      crossAxisCount: 2,
      childAspectRatio: 4,
      children: data.map((row) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(
            horizontal: 8, vertical: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey200),
          ),
        ),
        child: pw.Row(children: [
          pw.Text('${row[0]} : ',
              style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                  fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Text(row[1],
                style: const pw.TextStyle(fontSize: 10)),
          ),
        ]),
      )).toList(),
    );
  }

  static String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '--';
    final s = date.contains('T') ? date.split('T')[0] : date;
    if (s.length >= 10) {
      final p = s.substring(0, 10).split('-');
      if (p.length == 3) return '${p[2]}/${p[1]}/${p[0]}';
    }
    return s;
  }
}