import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String email;
  String? fullName;
  String? avatarUrl;
  String? bio;
  String? phoneNumber;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? phoneNumber,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: this.id,
      email: this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  // Create from Supabase response
  factory UserProfile.fromSupabase(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      phoneNumber: json['phone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'phone': phoneNumber,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
