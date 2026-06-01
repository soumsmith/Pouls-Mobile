class ReferredUser {
  final int? idparent;
  final String? parentUid;
  final String? nom;
  final String? prenoms;
  final String? phone;
  final String? referralCode;
  final String? referredBy;
  final int? balance;
  final int? points;
  final String? dateCreation;

  ReferredUser({
    this.idparent,
    this.parentUid,
    this.nom,
    this.prenoms,
    this.phone,
    this.referralCode,
    this.referredBy,
    this.balance,
    this.points,
    this.dateCreation,
  });

  factory ReferredUser.fromJson(Map<String, dynamic> json) {
    return ReferredUser(
      idparent: json['idparent'],
      parentUid: json['parent_uid'],
      nom: json['nom'],
      prenoms: json['prenoms'],
      phone: json['phone'],
      referralCode: json['referral_code'],
      referredBy: json['referred_by'],
      balance: json['balance'],
      points: json['points'],
      dateCreation: json['created_at'], // In case there's a date
    );
  }
}
