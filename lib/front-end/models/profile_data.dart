class ProfileData {
  final String id;
  final String name;
  final String email;
  final String phoneCountryCode;
  final String phoneNumberPart;
  final String role;
  final String? imageBase64;
  final bool showContactDetails;
  final bool showEmail;
  final bool showPhone;
  final String? username; // Added to support username

  ProfileData({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneCountryCode,
    required this.phoneNumberPart,
    required this.role,
    this.imageBase64,
    required this.showContactDetails,
    required this.showEmail,
    required this.showPhone,
    this.username,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneCountryCode': phoneCountryCode,
      'phoneNumberPart': phoneNumberPart,
      'role': role,
      'image_base64': imageBase64,
      'showContactDetails': showContactDetails,
      'showEmail': showEmail,
      'showPhone': showPhone,
      'username': username,
    };
  }

  factory ProfileData.fromMap(Map<String, dynamic> map) {
    return ProfileData(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      email: map['email'] as String? ?? '',
      phoneCountryCode: map['phoneCountryCode'] as String? ?? '+1',
      phoneNumberPart: map['phoneNumberPart'] as String? ?? '',
      role: map['role'] as String? ?? 'User',
      imageBase64: map['image_base64'] as String?,
      showContactDetails: map['showContactDetails'] as bool? ?? true,
      showEmail: map['showEmail'] as bool? ?? true,
      showPhone: map['showPhone'] as bool? ?? true,
      username: map['username'] as String?,
    );
  }
}