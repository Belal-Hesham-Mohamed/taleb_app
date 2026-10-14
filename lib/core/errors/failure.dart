enum FailureKind {
  invalidCredentials,
  emailAlreadyRegistered,
  network,
  sessionExpired,
  profileNotFound,
  profileUnavailable,
  pendingApproval,
  rejected,
  validation,
  unknown,
}

class Failure {
  const Failure(this.kind);
  final FailureKind kind;
}
