class ContactInfo {
  final String? name;
  final String? email;
  final String? phone;
  final String? preferredMethod;
  final bool allowFollowUp;
  final String? bestTimeToContact;
  final String? additionalNotes;

  ContactInfo({
    this.name,
    this.email,
    this.phone,
    this.preferredMethod,
    this.allowFollowUp = false,
    this.bestTimeToContact,
    this.additionalNotes,
  });

  bool get hasContactInfo => 
      (name?.isNotEmpty ?? false) || 
      (email?.isNotEmpty ?? false) || 
      (phone?.isNotEmpty ?? false);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'preferredMethod': preferredMethod,
      'allowFollowUp': allowFollowUp,
      'bestTimeToContact': bestTimeToContact,
      'additionalNotes': additionalNotes,
    };
  }

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      preferredMethod: json['preferredMethod'],
      allowFollowUp: json['allowFollowUp'] ?? false,
      bestTimeToContact: json['bestTimeToContact'],
      additionalNotes: json['additionalNotes'],
    );
  }

  ContactInfo copyWith({
    String? name,
    String? email,
    String? phone,
    String? preferredMethod,
    bool? allowFollowUp,
    String? bestTimeToContact,
    String? additionalNotes,
  }) {
    return ContactInfo(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      preferredMethod: preferredMethod ?? this.preferredMethod,
      allowFollowUp: allowFollowUp ?? this.allowFollowUp,
      bestTimeToContact: bestTimeToContact ?? this.bestTimeToContact,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }
}
