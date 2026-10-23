import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todocat/main.dart';
import 'package:todocat/models/task.dart';
import 'package:todocat/presentation/screens/about_screen.dart';
import 'package:todocat/presentation/screens/home/widgets/create_task_modal.dart';
import 'package:todocat/presentation/screens/home/widgets/home_tasks_view.dart';
import 'package:todocat/presentation/screens/legal_screen.dart';
import 'package:todocat/presentation/screens/login_screen.dart';

void main() {
  testWidgets('TodoCatApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoCatApp());
    expect(find.byType(TodoCatApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2000));
  });

  testWidgets('CreateTaskDialog opens and closes cleanly without assertion errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showCreateTaskModal(context, onTaskCreated: (_) {}),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    // Tap to open modal
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateTaskDialog), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Tap close button
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(CreateTaskDialog), findsNothing);
  });

  testWidgets('AboutScreen displays developer info and GitHub link', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AboutScreen(),
      ),
    );

    expect(find.text('About TodoCat'), findsOneWidget);
    expect(find.text('Nandakishore P'), findsOneWidget);
    expect(find.text('github.com/nanda-kshr'), findsOneWidget);
    expect(find.text('nandakishorep212@gmail.com'), findsOneWidget);
    expect(find.text('Buy Me a Coffee'), findsOneWidget);
  });

  testWidgets('LegalScreen displays privacy policy and terms of service tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LegalScreen(),
      ),
    );

    expect(find.text('Legal & Policies'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsWidgets);
    expect(find.text('Terms of Service'), findsWidgets);

    // Tap Terms of Service tab
    await tester.tap(find.text('Terms of Service'));
    await tester.pumpAndSettle();

    expect(find.text('1. Acceptance of Terms'), findsOneWidget);
  });

  testWidgets('LoginScreen displays legal disclaimer with terms and privacy links', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.textContaining('By signing in or signing up, you agree to our'), findsOneWidget);
    expect(find.text('Terms & Conditions'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });

  testWidgets('HomeTasksView renders without infinite height assertion when switching tabs', (tester) async {
    final now = DateTime.now();
    final tasks = [
      Task(
        id: '1',
        title: 'Active Task',
        description: 'Desc',
        completed: false,
        category: 'Work',
        priority: 'high',
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: '2',
        title: 'Completed Task',
        description: 'Desc',
        completed: true,
        category: 'Work',
        priority: 'medium',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];

    String currentFilter = 'all';

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            final filtered = tasks.where((t) {
              if (currentFilter == 'active' && t.completed) return false;
              if (currentFilter == 'completed' && !t.completed) return false;
              return true;
            }).toList();

            final today = filtered.where((t) => !t.completed || t.updatedAt?.day == now.day).toList();
            final earlierTasks = filtered.where((t) => t.completed && t.updatedAt?.day != now.day).toList();

            return Scaffold(
              body: HomeTasksView(
                scrollController: ScrollController(),
                onRefresh: () async {},
                catSpeed: 50,
                activeCount: 1,
                completedCount: 1,
                completedTodayCount: 0,
                todayTotalCount: 1,
                completionPercent: 0,
                totalCount: 2,
                currentFilter: currentFilter,
                onFilterChanged: (f) => setState(() => currentFilter = f),
                searchController: TextEditingController(),
                searchQuery: '',
                onSearchChanged: (_) {},
                filteredTasks: filtered,
                todayTasks: today,
                earlierTasks: earlierTasks,
                isLoadingMore: false,
                onToggleTask: (_) {},
                onTaskTap: (_) {},
                onDeleteTask: (_) {},
              ),
            );
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Switch to active
    await tester.tap(find.text('Active').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Switch to all
    await tester.tap(find.text('All').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Switch to completed
    await tester.tap(find.text('Completed').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);

    // Expand Completed Earlier button
    expect(find.text('Completed Earlier'), findsOneWidget);
    await tester.tap(find.text('Completed Earlier'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Completed Task'), findsOneWidget);

    // Collapse Completed Earlier button
    await tester.tap(find.text('Completed Earlier'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Completed Task'), findsNothing);
  });
}
