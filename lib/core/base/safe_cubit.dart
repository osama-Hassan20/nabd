import 'package:flutter_bloc/flutter_bloc.dart';

/// A base Cubit class that prevents emitting states after the cubit is closed.
///
/// All cubits in the project should extend this class instead of [Cubit]
/// to avoid `StateError: Cannot emit new states after calling close`.
///
/// ```dart
/// class MyCubit extends SafeCubit<MyState> {
///   MyCubit() : super(MyInitialState());
/// }
/// ```
abstract class SafeCubit<State> extends Cubit<State> {
  SafeCubit(super.initialState);

  @override
  void emit(State state) {
    if (isClosed) return;
    super.emit(state);
  }
}
