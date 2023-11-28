import 'package:cgk/union_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


typedef UnionStateContentBuilder<T> = Widget Function(T data);
typedef UnionStateLoadingBuilder = Widget Function();
typedef UnionStateErrorBuilder = Widget Function();

class ValueUnionStateListener<T> extends StatefulWidget {
  final ValueListenable<UnionState<T>> unionListenable;
  final UnionStateContentBuilder<T> contentBuilder;
  final UnionStateLoadingBuilder loadingBuilder;
  final UnionStateErrorBuilder errorBuilder;

  const ValueUnionStateListener({
    required this.unionListenable,
    required this.contentBuilder,
    required this.loadingBuilder,
    required this.errorBuilder,
    super.key,
  });

  @override
  State<ValueUnionStateListener<T>> createState() => _ValueUnionStateListenerState<T>();
}

class _ValueUnionStateListenerState<T> extends State<ValueUnionStateListener<T>> {
  late UnionState<T> state = widget.unionListenable.value;

  @override
  void initState() {
    widget.unionListenable.addListener(_unionStateListener);
    super.initState();
  }

  @override
  void dispose() {
    widget.unionListenable.removeListener(_unionStateListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      UnionState$Loading<T>() => widget.loadingBuilder(),
      final UnionState$Content<T> c => widget.contentBuilder(c.data),
      UnionState$Error<T>() => widget.errorBuilder(),
    };
  }

  void _unionStateListener() {
    state = widget.unionListenable.value;
    setState(() {});
  }
}