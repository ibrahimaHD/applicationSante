import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  static Future<void> exporterDossierMedical({
    required BuildContext context,
    required Map<String, dynamic> dossier,
    required String nomPatient,
  }) async {
    final pdf = pw.Document();

    final patient       = dossier['patient']        ?? {};
    final profil        = dossier['profil_medical'] ?? {};
    final consultations = dossier['consultations']  as List? ?? [];
    final vaccinations  = dossier['vaccinations']   as List? ?? [];
    final examens       = dossier['examens']        as List? ?? [];
    final resultats     = dossier['resultats']      as List? ?? [];
    final ordonnances   = dossier['ordonnances']    as List? ?? [];

    // ── Styles ────────────────────────────────────────────────────
    const colorPrimary   = PdfColor.fromInt(0xFF1E88E5);
    const colorSuccess   = PdfColor.fromInt(0xFF43A047);
    const colorSecondary = PdfColor.fromInt(0xFF546E7A);
    const colorBg        = PdfColor.fromInt(0xFFF5F9FF);

    final styleHeading = pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: colorPrimary);
    final styleLabel   = pw.TextStyle(fontSize: 10, color: colorSecondary);
    final styleValue   = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900);
    final styleNormal  = pw.TextStyle(fontSize: 10, color: PdfColors.grey800);

    // ── Helpers ───────────────────────────────────────────────────
    pw.Widget infoRow(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.SizedBox(width: 130, child: pw.Text(label, style: styleLabel)),
        pw.Expanded(child: pw.Text(value.trim().isEmpty ? '—' : value, style: styleValue)),
      ]),
    );

    pw.Widget sectionCard(String title, List<pw.Widget> children) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFE3F2FD),
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8), topRight: pw.Radius.circular(8)),
          ),
          child: pw.Text(title, style: styleHeading),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(14),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: children),
        ),
      ]),
    );

    pw.Widget cellule(String texte, pw.TextStyle style) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(texte, style: style),
    );

    // ── Construction du PDF ───────────────────────────────────────
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Column(children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('LaafiBa', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: colorPrimary)),
            pw.Text('Votre santé, notre priorité', style: pw.TextStyle(fontSize: 9, color: colorSecondary)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('DOSSIER MEDICAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: colorPrimary)),
            pw.Text('Généré le : ${_dateAujourdhui()}', style: pw.TextStyle(fontSize: 9, color: colorSecondary)),
          ]),
        ]),
        pw.SizedBox(height: 6),
        pw.Divider(color: colorPrimary, thickness: 1.5),
        pw.SizedBox(height: 6),
      ]),
      footer: (ctx) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('LaafiBa — Document confidentiel', style: pw.TextStyle(fontSize: 8, color: colorSecondary)),
        pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 8, color: colorSecondary)),
      ]),
      build: (_) => [
        // Bannière patient
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          margin: const pw.EdgeInsets.only(bottom: 20),
          decoration: pw.BoxDecoration(color: colorPrimary, borderRadius: pw.BorderRadius.circular(10)),
          child: pw.Row(children: [
            pw.Container(
              width: 48, height: 48,
              decoration: const pw.BoxDecoration(color: PdfColors.white, shape: pw.BoxShape.circle),
              child: pw.Center(child: pw.Text(
                _initiales(patient['prenom'] ?? '', patient['nom'] ?? ''),
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: colorPrimary),
              )),
            ),
            pw.SizedBox(width: 14),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(
                '${patient['prenom'] ?? ''} ${patient['nom'] ?? ''}'.trim(),
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              ),
              pw.Text(patient['email'] ?? '',     style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xCCFFFFFF))),
              pw.Text(patient['telephone'] ?? '', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xCCFFFFFF))),
            ]),
          ]),
        ),

        // Résumé rapide
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          margin: const pw.EdgeInsets.only(bottom: 20),
          decoration: pw.BoxDecoration(
            color: colorBg,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColor.fromInt(0xFF1E88E5), width: 0.5),
          ),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
            _resumeItem('Groupe sanguin', profil['groupe_sanguin'] ?? '—', styleLabel, styleValue),
            pw.Container(width: 1, height: 28, color: PdfColor.fromInt(0xFFBBDEFB)),
            _resumeItem('Taille',  profil['taille'] != null ? '${profil['taille']} cm' : '—', styleLabel, styleValue),
            pw.Container(width: 1, height: 28, color: PdfColor.fromInt(0xFFBBDEFB)),
            _resumeItem('Poids',   profil['poids']  != null ? '${profil['poids']} kg'  : '—', styleLabel, styleValue),
            pw.Container(width: 1, height: 28, color: PdfColor.fromInt(0xFFBBDEFB)),
            _resumeItem('Consultations', '${consultations.length}', styleLabel, styleValue),
            pw.Container(width: 1, height: 28, color: PdfColor.fromInt(0xFFBBDEFB)),
            _resumeItem('Vaccinations',  '${vaccinations.length}',  styleLabel, styleValue),
            pw.Container(width: 1, height: 28, color: PdfColor.fromInt(0xFFBBDEFB)),
            _resumeItem('Examens', '${examens.length}', styleLabel, styleValue),
          ]),
        ),

        // Identité
        sectionCard('Identité du patient', [
          infoRow('Nom complet',       '${patient['prenom'] ?? ''} ${patient['nom'] ?? ''}'),
          infoRow('Email',              patient['email']     ?? ''),
          infoRow('Téléphone',          patient['telephone'] ?? ''),
          infoRow('Date de naissance',  profil['date_naissance']?.toString() ?? ''),
          infoRow('Sexe',               _labelSexe(profil['sexe'])),
          infoRow('N° Assurance',       profil['numero_assurance'] ?? ''),
        ]),

        // Profil médical
        sectionCard('Profil médical', [
          infoRow('Groupe sanguin',      profil['groupe_sanguin'] ?? ''),
          infoRow('Taille',              profil['taille'] != null ? '${profil['taille']} cm' : ''),
          infoRow('Poids',               profil['poids']  != null ? '${profil['poids']} kg'  : ''),
          infoRow('Allergies',           profil['allergies']            ?? ''),
          infoRow('Antécédents',         profil['antecedents']          ?? ''),
          infoRow('Médicaments actuels', profil['medicaments_actuels']  ?? ''),
          infoRow('Médecin traitant',    profil['medecin_traitant']     ?? ''),
        ]),

        // Consultations
        sectionCard('Historique des consultations (${consultations.length})',
          consultations.isEmpty
            ? [pw.Text('Aucune consultation.', style: styleNormal)]
            : consultations.map((c) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: colorBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
                ),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text(c['motif'] ?? '', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: colorPrimary)),
                    pw.Text(c['date_consultation']?.toString() ?? '', style: pw.TextStyle(fontSize: 9, color: colorSecondary)),
                  ]),
                  if ((c['medecin_nom'] ?? '').isNotEmpty) ...[
                    pw.SizedBox(height: 3),
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
                ]),
              )).toList(),
        ),

        // Vaccinations
        sectionCard('Vaccinations (${vaccinations.length})',
          vaccinations.isEmpty
            ? [pw.Text('Aucune vaccination.', style: styleNormal)]
            : [pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE0E0E0), width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE3F2FD)),
                    children: [
                      cellule('Vaccin',         styleHeading),
                      cellule('Date',           styleHeading),
                      cellule('Rappel suivant', styleHeading),
                      cellule('Statut',         styleHeading),
                    ],
                  ),
                  ...vaccinations.map((v) => pw.TableRow(children: [
                    cellule(v['nom_vaccin'] ?? '',                     styleNormal),
                    cellule(v['date_vaccination']?.toString()  ?? '—', styleNormal),
                    cellule(v['prochain_rappel']?.toString()   ?? '—', styleNormal),
                    cellule(
                      v['statut'] == 'fait' ? 'Fait' : 'À faire',
                      pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: v['statut'] == 'fait' ? colorSuccess : PdfColors.orange,
                      ),
                    ),
                  ])),
                ],
              )],
        ),

        sectionCard('Examens et résultats (${examens.length + resultats.length})',
          examens.isEmpty && resultats.isEmpty
            ? [pw.Text('Aucun examen ou résultat.', style: styleNormal)]
            : [
                ...examens.map((e) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text(
                    '${e['date_examen'] ?? ''} - ${e['nom_examen'] ?? e['type_examen'] ?? 'Examen'}',
                    style: styleNormal,
                  ),
                )),
                ...resultats.map((r) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text(
                    '${r['date_resultat'] ?? ''} - ${r['nom_examen'] ?? r['type_examen'] ?? 'Résultat'} : ${r['resultat'] ?? r['conclusion'] ?? ''}',
                    style: styleNormal,
                  ),
                )),
              ],
        ),

        sectionCard('Ordonnances (${ordonnances.length})',
          ordonnances.isEmpty
            ? [pw.Text('Aucune ordonnance.', style: styleNormal)]
            : ordonnances.map((o) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: colorBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
                ),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Ordonnance du ${o['date_ordonnance'] ?? ''}',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: colorPrimary)),
                  if ((o['medicaments'] ?? '').toString().isNotEmpty)
                    pw.Text(o['medicaments'].toString(), style: styleNormal),
                  if ((o['instructions'] ?? '').toString().isNotEmpty)
                    pw.Text('Instructions : ${o['instructions']}', style: styleNormal),
                ]),
              )).toList(),
        ),

        // Pied de document
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Document généré automatiquement par LaafiBa',
                  style: pw.TextStyle(fontSize: 8, color: colorSecondary)),
              pw.Text('Ce document est confidentiel',
                  style: pw.TextStyle(fontSize: 8, color: colorSecondary, fontStyle: pw.FontStyle.italic)),
            ]),
            pw.Text(_dateAujourdhui(), style: pw.TextStyle(fontSize: 8, color: colorSecondary)),
          ]),
        ),
      ],
    ));

    // ── Sauvegarder dans le cache puis partager ───────────────────
    final nomFichier = 'dossier_${nomPatient.replaceAll(' ', '_')}.pdf';
    final Uint8List bytes = await pdf.save();

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: nomFichier,
          mimeType: 'application/pdf',
        ),
      ],
      subject: 'Dossier médical — $nomPatient',
      text: 'Dossier médical généré par LaafiBa le ${_dateAujourdhui()}',
    );
  }

  // ── Helpers privés ────────────────────────────────────────────────
  static String _dateAujourdhui() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
           '${now.month.toString().padLeft(2, '0')}/'
           '${now.year}';
  }

  static String _initiales(String prenom, String nom) {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty   ? nom[0].toUpperCase()    : '';
    return '$p$n';
  }

  static String _labelSexe(dynamic sexe) {
    switch (sexe) {
      case 'M':     return 'Masculin';
      case 'F':     return 'Féminin';
      case 'autre': return 'Autre';
      default:      return '—';
    }
  }

  static pw.Widget _resumeItem(
    String label, String value,
    pw.TextStyle labelStyle, pw.TextStyle valueStyle,
  ) => pw.Column(children: [
    pw.Text(value, style: valueStyle),
    pw.SizedBox(height: 2),
    pw.Text(label, style: labelStyle),
  ]);
}
