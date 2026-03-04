/// Modèle représentant un utilisateur (parent)
class User {
  final String id;
  final String? email;
  final String firstName;
  final String lastName;
  final String phone;
  final String? parentUid;
  final String? ville;
  final String? adresse;
  final String role;
  final String? referralCode;
  final int smsCredits;

  User({
    required this.id,
    this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.parentUid,
    this.ville,
    this.adresse,
    this.role = 'parent',
    this.referralCode,
    this.smsCredits = 0,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'],
      firstName: json['nom'] as String? ?? json['firstName'] as String? ?? '',
      lastName: json['prenoms'] as String? ?? json['lastName'] as String? ?? '',
      phone: json['mobile'] as String? ?? json['phone'] as String? ?? '',
      parentUid: json['parent_uid'],
      ville: json['ville'],
      adresse: json['adresse'],
      role: json['role'] as String? ?? 'parent',
      referralCode: json['referral_code'],
      smsCredits: json['smsCredits'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'parent_uid': parentUid,
      'ville': ville,
      'adresse': adresse,
      'role': role,
      'referral_code': referralCode,
      'smsCredits': smsCredits,
    };
  }

  /// Crée une copie de l'utilisateur avec des crédits SMS modifiés
  User copyWith({int? smsCredits}) {
    return User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      smsCredits: smsCredits ?? this.smsCredits,
    );
  }
}

