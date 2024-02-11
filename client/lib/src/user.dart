// Provide a top-level definition of a user
class User {
  int id;
  String? username;
  String? email;
  String? phone;

  User({
    this.id = 0,
    this.username = "",
    this.email = "",
    this.phone = "",
  });



  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phone: json['phone']
    );
  }
}