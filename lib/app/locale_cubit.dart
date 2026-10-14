import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/storage/locale_repository.dart';

class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit(this._repository) : super(null);
  final LocaleRepository _repository;

  Future<void> load() async {
    final code = await _repository.read();
    emit(code == null ? null : Locale(code));
  }

  Future<void> setLanguage(String code) async {
    await _repository.write(code);
    emit(Locale(code));
  }
}
