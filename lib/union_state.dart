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

}