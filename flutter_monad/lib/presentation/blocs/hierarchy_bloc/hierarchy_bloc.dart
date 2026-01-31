import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/hierarchy_model.dart';
import '../../../data/repositories/hierarchy_repository.dart';
import '../../../domain/entities/user.dart';

// Events
abstract class HierarchyEvent extends Equatable {
  const HierarchyEvent();
  
  @override
  List<Object?> get props => [];
}

class HierarchyLoadRequested extends HierarchyEvent {
  const HierarchyLoadRequested();
}

class HierarchyMembersLoadRequested extends HierarchyEvent {
  const HierarchyMembersLoadRequested();
}

class HierarchyMemberAddRequested extends HierarchyEvent {
  final String address;
  final String name;
  final int level;
  final String supervisorId;
  
  const HierarchyMemberAddRequested({
    required this.address,
    required this.name,
    required this.level,
    required this.supervisorId,
  });
  
  @override
  List<Object?> get props => [address, name, level, supervisorId];
}

class HierarchyMemberDetailRequested extends HierarchyEvent {
  final String memberId;
  
  const HierarchyMemberDetailRequested({required this.memberId});
  
  @override
  List<Object?> get props => [memberId];
}

// States
abstract class HierarchyState extends Equatable {
  const HierarchyState();
  
  @override
  List<Object?> get props => [];
}

class HierarchyInitial extends HierarchyState {
  const HierarchyInitial();
}

class HierarchyLoading extends HierarchyState {
  const HierarchyLoading();
}

class HierarchyTreeLoaded extends HierarchyState {
  final HierarchyNodeModel tree;
  final HierarchyStatsModel? stats;
  
  const HierarchyTreeLoaded({required this.tree, this.stats});
  
  @override
  List<Object?> get props => [tree, stats];
}

class HierarchyMembersLoaded extends HierarchyState {
  final List<User> members;
  
  const HierarchyMembersLoaded({required this.members});
  
  @override
  List<Object?> get props => [members];
}

class HierarchyMemberDetailLoaded extends HierarchyState {
  final User member;
  final List<User> subordinates;
  
  const HierarchyMemberDetailLoaded({
    required this.member,
    required this.subordinates,
  });
  
  @override
  List<Object?> get props => [member, subordinates];
}

class HierarchyActionSuccess extends HierarchyState {
  final String message;
  
  const HierarchyActionSuccess({required this.message});
  
  @override
  List<Object?> get props => [message];
}

class HierarchyError extends HierarchyState {
  final String message;
  
  const HierarchyError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class HierarchyBloc extends Bloc<HierarchyEvent, HierarchyState> {
  final HierarchyRepository _hierarchyRepository;
  
  HierarchyBloc({required HierarchyRepository hierarchyRepository})
      : _hierarchyRepository = hierarchyRepository,
        super(const HierarchyInitial()) {
    on<HierarchyLoadRequested>(_onHierarchyLoadRequested);
    on<HierarchyMembersLoadRequested>(_onHierarchyMembersLoadRequested);
    on<HierarchyMemberAddRequested>(_onHierarchyMemberAddRequested);
    on<HierarchyMemberDetailRequested>(_onHierarchyMemberDetailRequested);
  }
  
  Future<void> _onHierarchyLoadRequested(
    HierarchyLoadRequested event,
    Emitter<HierarchyState> emit,
  ) async {
    emit(const HierarchyLoading());
    
    try {
      final tree = await _hierarchyRepository.getHierarchyTree();
      final stats = await _hierarchyRepository.getHierarchyStats();
      
      if (tree != null) {
        emit(HierarchyTreeLoaded(tree: tree, stats: stats));
      } else {
        emit(const HierarchyError(message: 'Failed to load hierarchy'));
      }
    } catch (e) {
      emit(HierarchyError(message: e.toString()));
    }
  }
  
  Future<void> _onHierarchyMembersLoadRequested(
    HierarchyMembersLoadRequested event,
    Emitter<HierarchyState> emit,
  ) async {
    emit(const HierarchyLoading());
    
    try {
      final members = await _hierarchyRepository.getAllMembers();
      emit(HierarchyMembersLoaded(members: members));
    } catch (e) {
      emit(HierarchyError(message: e.toString()));
    }
  }
  
  Future<void> _onHierarchyMemberAddRequested(
    HierarchyMemberAddRequested event,
    Emitter<HierarchyState> emit,
  ) async {
    emit(const HierarchyLoading());
    
    try {
      final member = await _hierarchyRepository.addMember(
        address: event.address,
        name: event.name,
        level: event.level,
        supervisorId: event.supervisorId,
      );
      
      if (member != null) {
        emit(const HierarchyActionSuccess(message: 'Member added successfully'));
      } else {
        emit(const HierarchyError(message: 'Failed to add member'));
      }
    } catch (e) {
      emit(HierarchyError(message: e.toString()));
    }
  }
  
  Future<void> _onHierarchyMemberDetailRequested(
    HierarchyMemberDetailRequested event,
    Emitter<HierarchyState> emit,
  ) async {
    emit(const HierarchyLoading());
    
    try {
      final member = await _hierarchyRepository.getMemberById(event.memberId);
      
      if (member != null) {
        final subordinates = await _hierarchyRepository.getSubordinates(event.memberId);
        emit(HierarchyMemberDetailLoaded(member: member, subordinates: subordinates));
      } else {
        emit(const HierarchyError(message: 'Member not found'));
      }
    } catch (e) {
      emit(HierarchyError(message: e.toString()));
    }
  }
}
