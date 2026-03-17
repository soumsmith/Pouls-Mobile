/// Modèle représentant les détails complets d'une école
class EcoleDetail {
  final EcoleData data;
  final ClientInfo client;
  final List<dynamic> infrastructures;
  final List<dynamic> rubriques;
  final List<dynamic> videospecifiques;
  final String image;

  EcoleDetail({
    required this.data,
    required this.client,
    required this.infrastructures,
    required this.rubriques,
    required this.videospecifiques,
    required this.image,
  });

  factory EcoleDetail.fromJson(Map<String, dynamic> json) {
    return EcoleDetail(
      data: EcoleData.fromJson(json['data'] ?? {}),
      client: ClientInfo.fromJson(json['client'] ?? {}),
      infrastructures: json['infrastructures'] ?? [],
      rubriques: json['rubriques'] ?? [],
      videospecifiques: json['videospecifiques'] ?? [],
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.toJson(),
      'client': client.toJson(),
      'infrastructures': infrastructures,
      'rubriques': rubriques,
      'videospecifiques': videospecifiques,
      'image': image,
    };
  }
}

/// Données principales de l'école
class EcoleData {
  final int id;
  final String code;
  final String pos;
  final String ville;
  final String pays;
  final String gateway;
  final String type;
  final String serveur;
  final String sserveur;
  final String nom;
  final String? presentation;
  final String? minipresentation;
  final String adresse;
  final String telephone;
  final String? email;
  final String? site;
  final String codedren;
  final String numautorisation;
  final String dren;
  final String statut;
  final String periode;
  final int modetraitedonnees;
  final String typeperiode;
  final String annee;
  final String? lastedtgen;
  final String? lastptagen;
  final String? lastedtptagen;
  final int tolPtaEntree;
  final int tolPtaSortie;
  final int validationSeance;
  final String? logo;
  final String? imagefond;
  final String? slogan;
  final int modergpa;
  final int modeinsc;
  final int formatrecupaiement;
  final int autProfEditmoy;
  final String sourcedata;
  final double longitude;
  final double latitude;
  final int geolocationStatus;
  final int localisationPointage;
  final int rayonPointage;
  final String? debutPreinscrit;
  final String? finPreinscrit;
  final String? debutInscrit;
  final String? finInscrit;
  final int testEntree;
  final String? debutTest;
  final String? finTest;
  final String? debutReservation;
  final String? finReservation;
  final int montantReservation;
  final int autoriseEngagement;
  final String? referralCode;
  final String? referredBy;
  final int? effectif;
  final String? effectifcant;
  final String? effectifmoyclasse;
  final String? nbrannee;
  final String? programmelangue;
  final int inscriptionsatatus;
  final String? updatedAt;
  final int exportPouls;

  EcoleData({
    required this.id,
    required this.code,
    required this.pos,
    required this.ville,
    required this.pays,
    required this.gateway,
    required this.type,
    required this.serveur,
    required this.sserveur,
    required this.nom,
    this.presentation,
    this.minipresentation,
    required this.adresse,
    required this.telephone,
    this.email,
    this.site,
    required this.codedren,
    required this.numautorisation,
    required this.dren,
    required this.statut,
    required this.periode,
    required this.modetraitedonnees,
    required this.typeperiode,
    required this.annee,
    this.lastedtgen,
    this.lastptagen,
    this.lastedtptagen,
    required this.tolPtaEntree,
    required this.tolPtaSortie,
    required this.validationSeance,
    this.logo,
    this.imagefond,
    this.slogan,
    required this.modergpa,
    required this.modeinsc,
    required this.formatrecupaiement,
    required this.autProfEditmoy,
    required this.sourcedata,
    required this.longitude,
    required this.latitude,
    required this.geolocationStatus,
    required this.localisationPointage,
    required this.rayonPointage,
    this.debutPreinscrit,
    this.finPreinscrit,
    this.debutInscrit,
    this.finInscrit,
    required this.testEntree,
    this.debutTest,
    this.finTest,
    this.debutReservation,
    this.finReservation,
    required this.montantReservation,
    required this.autoriseEngagement,
    this.referralCode,
    this.referredBy,
    this.effectif,
    this.effectifcant,
    this.effectifmoyclasse,
    this.nbrannee,
    this.programmelangue,
    required this.inscriptionsatatus,
    this.updatedAt,
    required this.exportPouls,
  });

  factory EcoleData.fromJson(Map<String, dynamic> json) {
    return EcoleData(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      pos: json['pos'] ?? '',
      ville: json['ville'] ?? '',
      pays: json['pays'] ?? '',
      gateway: json['gateway'] ?? '',
      type: json['type'] ?? '',
      serveur: json['serveur'] ?? '',
      sserveur: json['sserveur'] ?? '',
      nom: json['nom'] ?? '',
      presentation: json['presentation'],
      minipresentation: json['minipresentation'],
      adresse: json['adresse'] ?? '',
      telephone: json['telephone'] ?? '',
      email: json['email'],
      site: json['site'],
      codedren: json['codedren'] ?? '',
      numautorisation: json['numautorisation'] ?? '',
      dren: json['dren'] ?? '',
      statut: json['statut'] ?? '',
      periode: json['periode'] ?? '',
      modetraitedonnees: json['modetraitedonnees'] ?? 0,
      typeperiode: json['typeperiode'] ?? '',
      annee: json['annee'] ?? '',
      lastedtgen: json['lastedtgen'],
      lastptagen: json['lastptagen'],
      lastedtptagen: json['lastedtptagen'],
      tolPtaEntree: json['tol_pta_entree'] ?? 0,
      tolPtaSortie: json['tol_pta_sortie'] ?? 0,
      validationSeance: json['validation_seance'] ?? 0,
      logo: json['logo'],
      imagefond: json['imagefond'],
      slogan: json['slogan'],
      modergpa: json['modergpa'] ?? 0,
      modeinsc: json['modeinsc'] ?? 0,
      formatrecupaiement: json['formatrecupaiement'] ?? 0,
      autProfEditmoy: json['aut_prof_editmoy'] ?? 0,
      sourcedata: json['sourcedata'] ?? '',
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      geolocationStatus: json['geolocation_status'] ?? 0,
      localisationPointage: json['localisation_pointage'] ?? 0,
      rayonPointage: json['rayon_pointage'] ?? 0,
      debutPreinscrit: json['debut_preinscrit'],
      finPreinscrit: json['fin_preinscrit'],
      debutInscrit: json['debut_inscrit'],
      finInscrit: json['fin_inscrit'],
      testEntree: json['test_entree'] ?? 0,
      debutTest: json['debut_test'],
      finTest: json['fin_test'],
      debutReservation: json['debut_reservation'],
      finReservation: json['fin_reservation'],
      montantReservation: json['montant_reservation'] ?? 0,
      autoriseEngagement: json['autorise_engagement'] ?? 0,
      referralCode: json['referral_code'],
      referredBy: json['referred_by'],
      effectif: json['effectif'] as int?,
      effectifcant: json['effectifcant']?.toString(),
      effectifmoyclasse: json['effectifmoyclasse']?.toString(),
      nbrannee: json['nbrannee']?.toString(),
      programmelangue: json['programmelangue'],
      inscriptionsatatus: json['inscriptionsatatus'] ?? 0,
      updatedAt: json['updated_at'],
      exportPouls: json['export_pouls'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'pos': pos,
      'ville': ville,
      'pays': pays,
      'gateway': gateway,
      'type': type,
      'serveur': serveur,
      'sserveur': sserveur,
      'nom': nom,
      'presentation': presentation,
      'minipresentation': minipresentation,
      'adresse': adresse,
      'telephone': telephone,
      'email': email,
      'site': site,
      'codedren': codedren,
      'numautorisation': numautorisation,
      'dren': dren,
      'statut': statut,
      'periode': periode,
      'modetraitedonnees': modetraitedonnees,
      'typeperiode': typeperiode,
      'annee': annee,
      'lastedtgen': lastedtgen,
      'lastptagen': lastptagen,
      'lastedtptagen': lastedtptagen,
      'tol_pta_entree': tolPtaEntree,
      'tol_pta_sortie': tolPtaSortie,
      'validation_seance': validationSeance,
      'logo': logo,
      'imagefond': imagefond,
      'slogan': slogan,
      'modergpa': modergpa,
      'modeinsc': modeinsc,
      'formatrecupaiement': formatrecupaiement,
      'aut_prof_editmoy': autProfEditmoy,
      'sourcedata': sourcedata,
      'longitude': longitude,
      'latitude': latitude,
      'geolocation_status': geolocationStatus,
      'localisation_pointage': localisationPointage,
      'rayon_pointage': rayonPointage,
      'debut_preinscrit': debutPreinscrit,
      'fin_preinscrit': finPreinscrit,
      'debut_inscrit': debutInscrit,
      'fin_inscrit': finInscrit,
      'test_entree': testEntree,
      'debut_test': debutTest,
      'fin_test': finTest,
      'debut_reservation': debutReservation,
      'fin_reservation': finReservation,
      'montant_reservation': montantReservation,
      'autorise_engagement': autoriseEngagement,
      'referral_code': referralCode,
      'referred_by': referredBy,
      'effectif': effectif,
      'effectifcant': effectifcant,
      'effectifmoyclasse': effectifmoyclasse,
      'nbrannee': nbrannee,
      'programmelangue': programmelangue,
      'inscriptionsatatus': inscriptionsatatus,
      'updated_at': updatedAt,
      'export_pouls': exportPouls,
    };
  }
}

/// Informations sur le client
class ClientInfo {
  final int clientId;
  final String code;
  final int annee;
  final String nom;
  final int effectif;
  final String type;
  final String licence;
  final String bdBase;
  final String bdHote;
  final int bdPort;
  final String bdUser;
  final String bdPasse;
  final int status;
  final int edtstatus;
  final String appspot;
  final String codesms;
  final String codepinsms;
  final String nomexp;
  final int compta;
  final int controleacces;
  final int relancessco;
  final int margeTolPtaEnt;
  final int margeTolPtaSor;
  final int autBulksms;
  final String? ecoleLogo;
  final int paiementEnLigne;
  final int fraisPel;
  final int smsSortie;
  final int systemeEducatif;
  final int margeEcole;
  final int margeGain;
  final int margeExceptionnelle;
  final int margeGainPourc;
  final int autoriseKitGain;
  final int effectifPrevisionnel;
  final int effectifAnneePrecedente;
  final int notemystatus;
  final String? referralCode;
  final String? referredBy;
  final int balance;
  final int separationFlux;
  final int inscriptionsatatus;
  final int appliVe;
  final int appliExterne;
  final String codepays;
  final String? nompays;
  final String? lienpays;
  final int faceidAnalyse;
  final int appelNumeric;
  final int badgeActif;
  final int notifFinSeance;

  ClientInfo({
    required this.clientId,
    required this.code,
    required this.annee,
    required this.nom,
    required this.effectif,
    required this.type,
    required this.licence,
    required this.bdBase,
    required this.bdHote,
    required this.bdPort,
    required this.bdUser,
    required this.bdPasse,
    required this.status,
    required this.edtstatus,
    required this.appspot,
    required this.codesms,
    required this.codepinsms,
    required this.nomexp,
    required this.compta,
    required this.controleacces,
    required this.relancessco,
    required this.margeTolPtaEnt,
    required this.margeTolPtaSor,
    required this.autBulksms,
    this.ecoleLogo,
    required this.paiementEnLigne,
    required this.fraisPel,
    required this.smsSortie,
    required this.systemeEducatif,
    required this.margeEcole,
    required this.margeGain,
    required this.margeExceptionnelle,
    required this.margeGainPourc,
    required this.autoriseKitGain,
    required this.effectifPrevisionnel,
    required this.effectifAnneePrecedente,
    required this.notemystatus,
    this.referralCode,
    this.referredBy,
    required this.balance,
    required this.separationFlux,
    required this.inscriptionsatatus,
    required this.appliVe,
    required this.appliExterne,
    required this.codepays,
    this.nompays,
    this.lienpays,
    required this.faceidAnalyse,
    required this.appelNumeric,
    required this.badgeActif,
    required this.notifFinSeance,
  });

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      clientId: json['client_id'] ?? 0,
      code: json['code'] ?? '',
      annee: json['annee'] ?? 0,
      nom: json['nom'] ?? '',
      effectif: json['effectif'] ?? 0,
      type: json['type'] ?? '',
      licence: json['licence'] ?? '',
      bdBase: json['bd_base'] ?? '',
      bdHote: json['bd_hote'] ?? '',
      bdPort: json['bd_port'] ?? 0,
      bdUser: json['bd_user'] ?? '',
      bdPasse: json['bd_passe'] ?? '',
      status: json['status'] ?? 0,
      edtstatus: json['edtstatus'] ?? 0,
      appspot: json['appspot'] ?? '',
      codesms: json['codesms'] ?? '',
      codepinsms: json['codepinsms'] ?? '',
      nomexp: json['nomexp'] ?? '',
      compta: json['compta'] ?? 0,
      controleacces: json['controleacces'] ?? 0,
      relancessco: json['relancessco'] ?? 0,
      margeTolPtaEnt: json['marge_tol_pta_ent'] ?? 0,
      margeTolPtaSor: json['marge_tol_pta_sor'] ?? 0,
      autBulksms: json['aut_bulksms'] ?? 0,
      ecoleLogo: json['ecole_logo'],
      paiementEnLigne: json['paiement_en_ligne'] ?? 0,
      fraisPel: json['frais_pel'] ?? 0,
      smsSortie: json['sms_sortie'] ?? 0,
      systemeEducatif: json['systeme_educatif'] ?? 0,
      margeEcole: json['marge_ecole'] ?? 0,
      margeGain: json['marge_gain'] ?? 0,
      margeExceptionnelle: json['marge_exceptionnelle'] ?? 0,
      margeGainPourc: json['marge_gain_pourc'] ?? 0,
      autoriseKitGain: json['autorise_kit_gain'] ?? 0,
      effectifPrevisionnel: json['effectif_previsionnel'] ?? 0,
      effectifAnneePrecedente: json['effectif_annee_precedente'] ?? 0,
      notemystatus: json['notemystatus'] ?? 0,
      referralCode: json['referral_code'],
      referredBy: json['referred_by'],
      balance: json['balance'] ?? 0,
      separationFlux: json['separation_flux'] ?? 0,
      inscriptionsatatus: json['inscriptionsatatus'] ?? 0,
      appliVe: json['appli_ve'] ?? 0,
      appliExterne: json['appli_externe'] ?? 0,
      codepays: json['codepays'] ?? '',
      nompays: json['nompays'],
      lienpays: json['lienpays'],
      faceidAnalyse: json['faceid_analyse'] ?? 0,
      appelNumeric: json['appel_numeric'] ?? 0,
      badgeActif: json['badge_actif'] ?? 0,
      notifFinSeance: json['notif_fin_seance'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'code': code,
      'annee': annee,
      'nom': nom,
      'effectif': effectif,
      'type': type,
      'licence': licence,
      'bd_base': bdBase,
      'bd_hote': bdHote,
      'bd_port': bdPort,
      'bd_user': bdUser,
      'bd_passe': bdPasse,
      'status': status,
      'edtstatus': edtstatus,
      'appspot': appspot,
      'codesms': codesms,
      'codepinsms': codepinsms,
      'nomexp': nomexp,
      'compta': compta,
      'controleacces': controleacces,
      'relancessco': relancessco,
      'marge_tol_pta_ent': margeTolPtaEnt,
      'marge_tol_pta_sor': margeTolPtaSor,
      'aut_bulksms': autBulksms,
      'ecole_logo': ecoleLogo,
      'paiement_en_ligne': paiementEnLigne,
      'frais_pel': fraisPel,
      'sms_sortie': smsSortie,
      'systeme_educatif': systemeEducatif,
      'marge_ecole': margeEcole,
      'marge_gain': margeGain,
      'marge_exceptionnelle': margeExceptionnelle,
      'marge_gain_pourc': margeGainPourc,
      'autorise_kit_gain': autoriseKitGain,
      'effectif_previsionnel': effectifPrevisionnel,
      'effectif_annee_precedente': effectifAnneePrecedente,
      'notemystatus': notemystatus,
      'referral_code': referralCode,
      'referred_by': referredBy,
      'balance': balance,
      'separation_flux': separationFlux,
      'inscriptionsatatus': inscriptionsatatus,
      'appli_ve': appliVe,
      'appli_externe': appliExterne,
      'codepays': codepays,
      'nompays': nompays,
      'lienpays': lienpays,
      'faceid_analyse': faceidAnalyse,
      'appel_numeric': appelNumeric,
      'badge_actif': badgeActif,
      'notif_fin_seance': notifFinSeance,
    };
  }
}
