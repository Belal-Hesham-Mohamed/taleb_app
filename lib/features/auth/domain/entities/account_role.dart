enum AccountRole { student, teacher, guardian }

extension AccountRoleValue on AccountRole {
  String get value => name;

  static AccountRole? parse(String? value) {
    for (final role in AccountRole.values) {
      if (role.name == value) return role;
    }
    return null;
  }
}
