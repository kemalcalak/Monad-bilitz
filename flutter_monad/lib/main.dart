import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/contract_repository.dart';
import 'data/repositories/hierarchy_repository.dart';
import 'data/services/api_service.dart';
import 'data/services/local_storage_service.dart';
import 'domain/usecases/sign_contract_usecase.dart';
import 'presentation/blocs/auth_bloc/auth_bloc.dart';
import 'presentation/blocs/contract_bloc/contract_bloc.dart';
import 'presentation/blocs/hierarchy_bloc/hierarchy_bloc.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/contracts_page.dart';
import 'presentation/pages/hierarchy_page.dart';
import 'presentation/pages/login_page.dart';

void main() {
  runApp(const SignatureApp());
}

class SignatureApp extends StatelessWidget {
  const SignatureApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final apiService = ApiService();
    final localStorageService = LocalStorageService();
    
    // Initialize repositories
    final authRepository = AuthRepository(
      apiService: apiService,
      localStorageService: localStorageService,
    );
    final contractRepository = ContractRepository(apiService: apiService);
    final hierarchyRepository = HierarchyRepository(apiService: apiService);
    
    // Initialize use cases
    final signContractUseCase = SignContractUseCase(
      contractRepository: contractRepository,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository: authRepository)
            ..add(const AuthCheckRequested()),
        ),
        BlocProvider<ContractBloc>(
          create: (_) => ContractBloc(
            contractRepository: contractRepository,
            signContractUseCase: signContractUseCase,
          ),
        ),
        BlocProvider<HierarchyBloc>(
          create: (_) => HierarchyBloc(hierarchyRepository: hierarchyRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Signature',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Wrapper widget that shows LoginPage or MainNavigationPage based on auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (state is AuthAuthenticated) {
          return const MainNavigationPage();
        }
        
        return const LoginPage();
      },
    );
  }
}

/// Main navigation page with bottom navigation bar
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => MainNavigationPageState();
}

class MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    ContractsPage(),
    HierarchyPage(),
  ];

  // Method to programmatically change tabs (used by dashboard)
  void setTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.buttonColor.withValues(alpha: 0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: 'Contracts',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_tree_outlined),
              selectedIcon: Icon(Icons.account_tree),
              label: 'Hierarchy',
            ),
          ],
        ),
      ),
    );
  }
}
