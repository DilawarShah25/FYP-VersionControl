class ProfileData {
  final String? id;
  final String? name;
  final String? email;
  final String? phoneCountryCode;
  final String? phoneNumberPart;
  final String? role;
  final String? imageUrl; // Firebase Storage URL
  final String? imagePath; // Local file path

  ProfileData({
    this.id,
    this.name,
    this.email,
    this.phoneCountryCode,
    this.phoneNumberPart,
    this.role,
    this.imageUrl,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneCountryCode': phoneCountryCode,
      'phoneNumberPart': phoneNumberPart,
      'role': role,
      'imageUrl': imageUrl,
    };
  }

  factory ProfileData.fromMap(Map<String, dynamic> map) {
    return ProfileData(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phoneCountryCode: map['phoneCountryCode'],
      phoneNumberPart: map['phoneNumberPart'],
      role: map['role'],
      imageUrl: map['imageUrl'],
    );
  }
}