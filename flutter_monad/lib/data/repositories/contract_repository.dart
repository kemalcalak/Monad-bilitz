import '../models/contract_model.dart';
import '../services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../domain/entities/contract.dart';

/// Repository for contract operations
class ContractRepository {
  final ApiService _apiService;

  ContractRepository({required ApiService apiService}) : _apiService = apiService;

  /// Get all contracts
  Future<List<Contract>> getContracts({
    String? status,
    int? page,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status_filter'] = status.toLowerCase();
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await _apiService.get<List<dynamic>>(
      ApiConfig.contractsEndpoint,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
      fromJson: (data) => data as List<dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      return response.data!
          .map((json) => ContractModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();
    }

    return [];
  }

  /// Get contract by ID (uses contract_id like CONTRACT_XXXX)
  Future<Contract?> getContractById(String contractId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiConfig.contractsEndpoint}/$contractId',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      return ContractModel.fromJson(response.data!).toEntity();
    }

    return null;
  }

  /// Create a new contract (matches backend ContractCreate schema)
  Future<Contract?> createContract({
    required String title,
    required String content,
    required String contractType,
    double? amount,
    String urgency = 'normal',
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConfig.contractsEndpoint,
      body: {
        'title': title,
        'content': content,
        'contract_type': contractType,
        if (amount != null) 'amount': amount,
        'urgency': urgency,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      return ContractModel.fromJson(response.data!).toEntity();
    }

    return null;
  }

  /// Sign/Approve a contract (uses contract_id like CONTRACT_XXXX)
  Future<bool> approveContract(String contractId) async {
    final response = await _apiService.post(
      '${ApiConfig.contractsEndpoint}/$contractId/sign',
    );

    return response.isSuccess;
  }

  /// Reject a contract (uses contract_id like CONTRACT_XXXX)
  Future<bool> rejectContract(String contractId, String reason) async {
    final response = await _apiService.post(
      '${ApiConfig.contractsEndpoint}/$contractId/reject',
      body: {'reason': reason},
    );

    return response.isSuccess;
  }

  /// Get pending contracts for current user
  Future<List<Contract>> getPendingContracts() async {
    return getContracts(status: 'pending');
  }

  /// Get contracts created by current user
  Future<List<Contract>> getMyContracts() async {
    final response = await _apiService.get<List<dynamic>>(
      '${ApiConfig.contractsEndpoint}/my',
      fromJson: (data) => data as List<dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      return response.data!
          .map((json) => ContractModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();
    }

    return [];
  }
}
