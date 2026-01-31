import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/contract_repository.dart';
import '../../../data/services/websocket_service.dart';
import '../../../domain/entities/contract.dart';
import '../../../domain/usecases/sign_contract_usecase.dart';

// Events
abstract class ContractEvent extends Equatable {
  const ContractEvent();

  @override
  List<Object?> get props => [];
}

class ContractsLoadRequested extends ContractEvent {
  final String? status;

  const ContractsLoadRequested({this.status});

  @override
  List<Object?> get props => [status];
}

class ContractDetailRequested extends ContractEvent {
  final String contractId;

  const ContractDetailRequested({required this.contractId});

  @override
  List<Object?> get props => [contractId];
}

class ContractCreateRequested extends ContractEvent {
  final String title;
  final String content;
  final String contractType;
  final double? amount;
  final String urgency;

  const ContractCreateRequested({
    required this.title,
    required this.content,
    required this.contractType,
    this.amount,
    this.urgency = 'normal',
  });

  @override
  List<Object?> get props => [title, content, contractType, amount, urgency];
}

class ContractApproveRequested extends ContractEvent {
  final String contractId;

  const ContractApproveRequested({required this.contractId});

  @override
  List<Object?> get props => [contractId];
}

class ContractRejectRequested extends ContractEvent {
  final String contractId;
  final String reason;

  const ContractRejectRequested({
    required this.contractId,
    required this.reason,
  });

  @override
  List<Object?> get props => [contractId, reason];
}

class ContractWebSocketEvent extends ContractEvent {
  final WebSocketMessage message;

  const ContractWebSocketEvent({required this.message});

  @override
  List<Object?> get props => [message];
}

// States
abstract class ContractState extends Equatable {
  const ContractState();

  @override
  List<Object?> get props => [];
}

class ContractInitial extends ContractState {
  const ContractInitial();
}

class ContractLoading extends ContractState {
  const ContractLoading();
}

class ContractsLoaded extends ContractState {
  final List<Contract> contracts;

  const ContractsLoaded({required this.contracts});

  @override
  List<Object?> get props => [contracts];
}

class ContractDetailLoaded extends ContractState {
  final Contract contract;

  const ContractDetailLoaded({required this.contract});

  @override
  List<Object?> get props => [contract];
}

class ContractActionSuccess extends ContractState {
  final String message;
  final Contract? contract;

  const ContractActionSuccess({required this.message, this.contract});

  @override
  List<Object?> get props => [message, contract];
}

class ContractError extends ContractState {
  final String message;

  const ContractError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class ContractBloc extends Bloc<ContractEvent, ContractState> {
  final ContractRepository _contractRepository;
  final SignContractUseCase _signContractUseCase;
  StreamSubscription<WebSocketMessage>? _wsSubscription;

  ContractBloc({
    required ContractRepository contractRepository,
    required SignContractUseCase signContractUseCase,
    WebSocketService? webSocketService,
  })  : _contractRepository = contractRepository,
        _signContractUseCase = signContractUseCase,
        super(const ContractInitial()) {
    on<ContractsLoadRequested>(_onContractsLoadRequested);
    on<ContractDetailRequested>(_onContractDetailRequested);
    on<ContractCreateRequested>(_onContractCreateRequested);
    on<ContractApproveRequested>(_onContractApproveRequested);
    on<ContractRejectRequested>(_onContractRejectRequested);
    on<ContractWebSocketEvent>(_onWebSocketEvent);

    // Subscribe to WebSocket events for real-time updates
    if (webSocketService != null) {
      _wsSubscription = webSocketService.messageStream.listen((message) {
        if (message.type == 'contract_created' ||
            message.type == 'signature_added' ||
            message.type == 'contract_finalized') {
          add(ContractWebSocketEvent(message: message));
        }
      });
    }
  }

  Future<void> _onContractsLoadRequested(
    ContractsLoadRequested event,
    Emitter<ContractState> emit,
  ) async {
    emit(const ContractLoading());

    try {
      final contracts = await _contractRepository.getContracts(status: event.status);
      emit(ContractsLoaded(contracts: contracts));
    } catch (e) {
      emit(ContractError(message: e.toString()));
    }
  }

  Future<void> _onContractDetailRequested(
    ContractDetailRequested event,
    Emitter<ContractState> emit,
  ) async {
    emit(const ContractLoading());

    try {
      final contract = await _contractRepository.getContractById(event.contractId);

      if (contract != null) {
        emit(ContractDetailLoaded(contract: contract));
      } else {
        emit(const ContractError(message: 'Contract not found'));
      }
    } catch (e) {
      emit(ContractError(message: e.toString()));
    }
  }

  Future<void> _onContractCreateRequested(
    ContractCreateRequested event,
    Emitter<ContractState> emit,
  ) async {
    emit(const ContractLoading());

    try {
      final contract = await _contractRepository.createContract(
        title: event.title,
        content: event.content,
        contractType: event.contractType,
        amount: event.amount,
        urgency: event.urgency,
      );

      if (contract != null) {
        emit(ContractActionSuccess(
          message: 'Contract created successfully',
          contract: contract,
        ));
      } else {
        emit(const ContractError(message: 'Failed to create contract'));
      }
    } catch (e) {
      emit(ContractError(message: e.toString()));
    }
  }

  Future<void> _onContractApproveRequested(
    ContractApproveRequested event,
    Emitter<ContractState> emit,
  ) async {
    emit(const ContractLoading());

    try {
      final result = await _signContractUseCase.execute(event.contractId);

      if (result.isSuccess) {
        emit(ContractActionSuccess(
          message: 'Contract approved successfully',
          contract: result.contract,
        ));
      } else {
        emit(ContractError(message: result.errorMessage ?? 'Approval failed'));
      }
    } catch (e) {
      emit(ContractError(message: e.toString()));
    }
  }

  Future<void> _onContractRejectRequested(
    ContractRejectRequested event,
    Emitter<ContractState> emit,
  ) async {
    emit(const ContractLoading());

    try {
      final result = await _signContractUseCase.reject(event.contractId, event.reason);

      if (result.isSuccess) {
        emit(ContractActionSuccess(
          message: 'Contract rejected',
          contract: result.contract,
        ));
      } else {
        emit(ContractError(message: result.errorMessage ?? 'Rejection failed'));
      }
    } catch (e) {
      emit(ContractError(message: e.toString()));
    }
  }

  Future<void> _onWebSocketEvent(
    ContractWebSocketEvent event,
    Emitter<ContractState> emit,
  ) async {
    // Refresh contract list when real-time updates arrive
    try {
      final contracts = await _contractRepository.getContracts();
      emit(ContractsLoaded(contracts: contracts));
    } catch (e) {
      // Silently ignore WebSocket refresh errors
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
