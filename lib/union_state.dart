
import 'package:flutter/material.dart';

sealed class UnionState<T>{

}

//состояние загрузки
class UnionState$Loading<T> extends UnionState<T>{

}

//состояние отображения контента
class UnionState$Content<T> extends UnionState<T>{
  final T data;
  UnionState$Content(this.data);
}

//состояние ошибки
class UnionState$Error<T> extends UnionState<T>{
  final Exception exception;
  UnionState$Error(this.exception);
}

class UnionStateNotifier<T> extends ValueNotifier<UnionState<T>>{
  UnionStateNotifier(super._value);

  void content(T content) => value = UnionState$Content<T>(content);
  void error(Exception exception) => value = UnionState$Error<T>(exception);
  void loading() => value = UnionState$Loading();
}