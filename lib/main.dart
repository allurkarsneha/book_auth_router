import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => AuthenticationBloc(),
      child: const MyApp(),
    ),
  );
}

enum AuthenticationStatus {
  loggedIn,
  notLoggedIn,
}

class AuthenticationState {
  final AuthenticationStatus status;

  const AuthenticationState(this.status);
}

class AuthenticationBloc extends Cubit<AuthenticationState> {
  AuthenticationBloc()
      : super(const AuthenticationState(AuthenticationStatus.notLoggedIn));

  void login() {
    emit(const AuthenticationState(AuthenticationStatus.loggedIn));
  }

  void logout() {
    emit(const AuthenticationState(AuthenticationStatus.notLoggedIn));
  }
}

class RefreshListenable extends ChangeNotifier {
  late final StreamSubscription _subscription;

  RefreshListenable(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

CustomTransitionPage fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 150),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  GoRouter _router(BuildContext context) {
    final authenticationBloc = context.read<AuthenticationBloc>();

    return GoRouter(
      initialLocation: '/byAuthor',
      refreshListenable: RefreshListenable(authenticationBloc.stream),
      redirect: (context, state) {
        final authState = authenticationBloc.state;
        final currentPath = state.uri.path;

        final isLoggedIn = authState.status == AuthenticationStatus.loggedIn;
        final isOnLoginPage = currentPath == '/login';

        if (isLoggedIn && isOnLoginPage) {
          return '/byAuthor';
        }

        if (!isLoggedIn && !isOnLoginPage) {
          return '/login';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          pageBuilder: (context, state) {
            return fadePage(
              state: state,
              child: const LoginPage(),
            );
          },
        ),
        GoRoute(
          path: '/byAuthor/detail',
          name: 'byAuthorDetail',
          pageBuilder: (context, state) {
            return fadePage(
              state: state,
              child: const DetailPage(),
            );
          },
        ),
        GoRoute(
          path: '/byTitle/detail',
          name: 'byTitleDetail',
          pageBuilder: (context, state) {
            return fadePage(
              state: state,
              child: const DetailPage(),
            );
          },
        ),
        ShellRoute(
          pageBuilder: (context, state, child) {
            return fadePage(
              state: state,
              child: AppShell(child: child),
            );
          },
          routes: [
            GoRoute(
              path: '/byAuthor',
              name: 'byAuthor',
              pageBuilder: (context, state) {
                return fadePage(
                  state: state,
                  child: const BooksPage(
                    pageTitle: 'Sorted by Author',
                  ),
                );
              },
            ),
            GoRoute(
              path: '/byTitle',
              name: 'byTitle',
              pageBuilder: (context, state) {
                return fadePage(
                  state: state,
                  child: const BooksPage(
                    pageTitle: 'Sorted by Title',
                  ),
                );
              },
            ),
            GoRoute(
              path: '/profile',
              name: 'profile',
              pageBuilder: (context, state) {
                return fadePage(
                  state: state,
                  child: const ProfilePage(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Book Auth Router',
      debugShowCheckedModeBanner: false,
      routerConfig: _router(context),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF7FF),
          surfaceTintColor: Color(0xFFFFF7FF),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
          iconTheme: IconThemeData(
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location.startsWith('/byTitle')) {
      return 1;
    }

    if (location.startsWith('/profile')) {
      return 2;
    }

    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      context.goNamed('byAuthor');
    } else if (index == 1) {
      context.goNamed('byTitle');
    } else {
      context.goNamed('profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(selectedIndex == 2 ? 'Profile' : 'Books'),
        leading: const Icon(Icons.menu),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: const Color(0xFFFFF7FF),
          indicatorColor: const Color(0xFFE8D9F7),
          height: 72,
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (states) {
              return TextStyle(
                fontSize: 12,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: Colors.black87,
              );
            },
          ),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (states) {
              return const IconThemeData(
                color: Colors.black87,
                size: 24,
              );
            },
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _onItemTapped(context, index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'By Author',
            ),
            NavigationDestination(
              icon: Icon(Icons.title),
              label: 'By Title',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: SizedBox(
          width: 290,
          height: 36,
          child: ElevatedButton(
            onPressed: () {
              context.read<AuthenticationBloc>().login();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF715CA5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Text(
              'Login',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}

class BooksPage extends StatelessWidget {
  final String pageTitle;

  const BooksPage({
    super.key,
    required this.pageTitle,
  });

  final List<Map<String, String>> books = const [
    {
      'title': 'Da Vinci Code',
      'author': 'Dan Brown',
    },
    {
      'title': 'Harry Potter',
      'author': 'J. K. Rowling',
    },
    {
      'title': 'The Alchemist',
      'author': 'Paulo Coelho',
    },
    {
      'title': 'Atomic Habits',
      'author': 'James Clear',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final sortedBooks = [...books];

    if (pageTitle == 'Sorted by Author') {
      sortedBooks.sort(
        (a, b) => a['author']!.compareTo(b['author']!),
      );
    } else {
      sortedBooks.sort(
        (a, b) => a['title']!.compareTo(b['title']!),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(32, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pageTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: sortedBooks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final book = sortedBooks[index];

                return InkWell(
                  onTap: () {
                    if (pageTitle == 'Sorted by Author') {
                      context.pushNamed('byAuthorDetail');
                    } else {
                      context.pushNamed('byTitleDetail');
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 68,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                    color: const Color(0xFFFFF7FF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book['title']!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book['author']!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Book'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.fromLTRB(32, 36, 32, 0),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            'Detail of the Book',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: SizedBox(
          width: 290,
          height: 36,
          child: ElevatedButton(
            onPressed: () {
              context.read<AuthenticationBloc>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF715CA5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}