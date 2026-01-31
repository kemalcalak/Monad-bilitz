import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/websocket_service.dart';
import '../../../domain/entities/user.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String address;
  final String signature;

  const AuthLoginRequested({
    required this.address,
    required this.signature,
  });

  @override
  List<Object?> get props => [address, signature];
}

class AuthLoginWithCredentialsRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginWithCredentialsRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String? walletAddress;

  const AuthRegisterRequested({
    required this.username,
    required this.email,
    required this.password,
    this.walletAddress,
  });

  @override
  List<Object?> get props => [username, email, password, walletAddress];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final WebSocketService _webSocketService;

  AuthBloc({
    required AuthRepository authRepository,
    required WebSocketService webSocketService,
  })  : _authRepository = authRepository,
        _webSocketService = webSocketService,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLoginWithCredentialsRequested>(_onAuthLoginWithCredentials);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.restoreSession();

      if (user != null) {
        await _connectWebSocket();
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.loginWithWallet(
        event.address,
        event.signature,
      );

      if (user != null) {
        await _connectWebSocket();
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthError(message: 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthLoginWithCredentials(
    AuthLoginWithCredentialsRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.login(
        username: event.username,
        password: event.password,
      );

      if (user != null) {
        await _connectWebSocket();
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthError(message: 'Invalid username or password'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.register(
        username: event.username,
        email: event.email,
        password: event.password,
        walletAddress: event.walletAddress,
      );

      if (user != null) {
        // After registration, auto-login
        final loggedInUser = await _authRepository.login(
          username: event.username,
          password: event.password,
        );
        if (loggedInUser != null) {
          await _connectWebSocket();
          emit(AuthAuthenticated(user: loggedInUser));
        } else {
          emit(const AuthError(message: 'Registration succeeded but login failed'));
        }
      } else {
        emit(const AuthError(message: 'Registration failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _webSocketService.disconnect();
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _connectWebSocket() async {
    final token = await _authRepository.getStoredToken();
    if (token != null) {
      _webSocketService.connect(token: token);
    }
  }

  @override
  Future<void> close() {
    _webSocketService.disconnect();
    return super.close();
  }
}
