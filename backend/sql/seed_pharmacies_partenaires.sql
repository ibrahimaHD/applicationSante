-- Donnees minimales pour activer le catalogue de medicaments par pharmacie partenaire.
-- A executer apres l'import de health_db.

SET @pharmacien_id := (SELECT id FROM pharmaciens ORDER BY id ASC LIMIT 1);

INSERT INTO pharmacies_partenaires
  (pharmacien_id, nom, adresse, telephone, horaires, est_actif, delai_livraison_min, frais_livraison)
SELECT @pharmacien_id, 'Pharmacie Centrale', 'Avenue Loudun, Bobo-Dioulasso', '+226 20 97 00 10', 'Lun-Sam 7h30-21h | Dim 9h-13h', 1, 30, 500
WHERE @pharmacien_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM pharmacies_partenaires WHERE nom = 'Pharmacie Centrale');

INSERT INTO pharmacies_partenaires
  (pharmacien_id, nom, adresse, telephone, horaires, est_actif, delai_livraison_min, frais_livraison)
SELECT @pharmacien_id, 'Pharmacie de la Paix', 'Secteur 7, Bobo-Dioulasso', '+226 20 97 11 20', 'Lun-Sam 7h30-20h', 1, 45, 500
WHERE @pharmacien_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM pharmacies_partenaires WHERE nom = 'Pharmacie de la Paix');

INSERT INTO pharmacies_partenaires
  (pharmacien_id, nom, adresse, telephone, horaires, est_actif, delai_livraison_min, frais_livraison)
SELECT @pharmacien_id, 'Pharmacie Esperance', 'Secteur 22, Bobo-Dioulasso', '+226 20 97 22 30', 'Lun-Sam 8h-20h', 1, 45, 700
WHERE @pharmacien_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM pharmacies_partenaires WHERE nom = 'Pharmacie Esperance');

UPDATE medicaments
SET pharmacie_id = (SELECT id FROM pharmacies_partenaires WHERE nom = 'Pharmacie Centrale' LIMIT 1)
WHERE id IN (1, 2, 3);

UPDATE medicaments
SET pharmacie_id = (SELECT id FROM pharmacies_partenaires WHERE nom = 'Pharmacie de la Paix' LIMIT 1)
WHERE id IN (4, 5, 6);

UPDATE medicaments
SET pharmacie_id = (SELECT id FROM pharmacies_partenaires WHERE nom = 'Pharmacie Esperance' LIMIT 1)
WHERE id IN (7, 8, 9, 10);
