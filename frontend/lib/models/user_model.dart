class UserModel {
  final int? id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String role;
  final String? token;
  final String? avatar;
  final bool isActive;
  final DateTime? createdAt;

  // Champs spécifiques aux rôles
  final String? specialite;       // Médecin
  final String? numerolicence;    // Médecin / Pharmacien
  final String? nomPharmacie;     // Pharmacien
  final String? vehicleType;      // Livreur
  final String? zone;             // Livreur

  UserModel({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.role,
    this.token,
    this.avatar,
    this.isActive = true,
    this.createdAt,
    this.specialite,
    this.numerolicence,
    this.nomPharmacie,
    this.vehicleType,
    this.zone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
      role: json['role'] ?? 'patient',
      token: json['token'],
      avatar: json['avatar'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      specialite: json['specialite'],
      numerolicence: json['numero_licence'],
      nomPharmacie: json['nom_pharmacie'],
      vehicleType: json['vehicle_type'],
      zone: json['zone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'role': role,
      'token': token,
      'avatar': avatar,
      'is_active': isActive,
      'specialite': specialite,
      'numero_licence': numerolicence,
      'nom_pharmacie': nomPharmacie,
      'vehicle_type': vehicleType,
      'zone': zone,
    };
  }

  String get fullName => '$prenom $nom';

  bool get isAdmin =>
      role == 'admin_jds' || role == 'super_admin';

  bool get isMedecin => role == 'medecin';
  bool get isPatient => role == 'patient';
  bool get isPharmacien => role == 'pharmacien';
  bool get isLivreur => role == 'livreur';
  bool get isSuperAdmin => role == 'super_admin';

  UserModel copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? role,
    String? token,
    String? avatar,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      role: role ?? this.role,
      token: token ?? this.token,
      avatar: avatar ?? this.avatar,
      isActive: isActive ?? this.isActive,
    );
  }
}
