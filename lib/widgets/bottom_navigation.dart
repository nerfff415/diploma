import 'package:flutter/material.dart';
import '../screens/first_aid_kits_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/family_groups_screen.dart';
import '../screens/medication_journal_screen.dart';
import '../screens/medication_search_screen.dart';
import '../screens/reminders_screen.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({Key? key}) : super(key: key);

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 0;

  // Список экранов для отображения
  final List<Widget> _screens = [
    const FirstAidKitsListScreen(),
    const FamilyGroupsScreen(),
    const MedicationJournalScreen(),
    const MedicationSearchScreen(),
    const ProfileScreen(),
  ];

  // Обработчик нажатия на элемент навигации
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Аптечки',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Группы'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Журнал',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Поиск'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
