class LoginParamModel {
  final String userName;
  final String password;

  LoginParamModel({required this.userName, required this.password});

  Map<String, dynamic> toJson() => {'userName': userName, 'password': password};
}
