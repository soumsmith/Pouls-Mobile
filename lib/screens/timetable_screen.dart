import 'package:flutter/material.dart';
import '../models/timetable_entry.dart';
import '../services/api_service.dart';
import '../services/text_size_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_card.dart';
import '../config/app_colors.dart';

/// Écran d'affichage de l'emploi du temps
class TimetableScreen extends StatefulWidget {
  final String childId;

  const TimetableScreen({
    super.key,
    required this.childId,
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<TimetableEntry> _timetable = [];
  bool _isLoading = true;
  final TextSizeService _textSizeService = TextSizeService();
  String? _selectedDay;
  
  // Cache pour les couleurs générées dynamiquement
  final Map<String, Color> _subjectColorCache = {};

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = MainScreenWrapper.of(context).apiService;
      final timetable = await apiService.getTimetableForChild(widget.childId);
      
      setState(() {
        _timetable = timetable;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e', style: TextStyle(fontSize: _textSizeService.getScaledFontSize(14)))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _textSizeService,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      AppColors.getPureBackground(true),
                      AppColors.primary.withOpacity(0.1),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF0F7FF),
                    ],
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _timetable.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        _buildDaySelector(),
                        Expanded(child: _buildTimetableContent()),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.event_available,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun cours aujourd\'hui',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(18),
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Profitez de votre journée !',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(14),
              color: AppColors.getTextColor(isDark, type: TextType.secondary).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final today = DateTime.now().weekday - 1; // 0 = Lundi
    final selectedIndex = _selectedDay != null 
        ? days.indexOf(_selectedDay!) 
        : (today >= 0 && today < days.length ? today : 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 50,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ]
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 3),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _selectedDay == day;
          final isToday = today == index;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = day;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(14),
                      fontWeight: FontWeight.w500,
                      color: isSelected 
                          ? Colors.white 
                          : AppColors.getTextColor(isDark, type: TextType.secondary),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isToday)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimetableContent() {
    if (_selectedDay == null) {
      // Afficher le jour actuel par défaut
      final today = DateTime.now().weekday - 1;
      final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
      if (today >= 0 && today < days.length) {
        _selectedDay = days[today];
      } else {
        _selectedDay = 'Lundi';
      }
    }
    
    final dayEntries = _timetable.where((entry) => entry.dayOfWeek == _selectedDay).toList();
    dayEntries.sort((a, b) => a.startTime.hour.compareTo(b.startTime.hour));
    
    if (dayEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun cours ce jour',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(16),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayEntries.length,
      itemBuilder: (context, index) {
        final entry = dayEntries[index];
        final subjectColor = _getSubjectColor(entry.subject);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceColor(isDark),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Bande de couleur pour l'heure - plus large
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: subjectColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
                // Contenu de l'heure - plus compact
                Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${entry.startTime.hour.toString().padLeft(2, '0')}:${entry.startTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(16),
                              fontWeight: FontWeight.bold,
                              color: subjectColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '-',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(14),
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${entry.endTime.hour.toString().padLeft(2, '0')}:${entry.endTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(12),
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Séparateur subtil
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                ),
                // Contenu principal - plus compact
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Badge matière plus compact
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: subjectColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: subjectColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                entry.subject,
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(13),
                                  fontWeight: FontWeight.w700,
                                  color: subjectColor,
                                ),
                              ),
                            ),
                            if (entry.room != null) ...[
                              const Spacer(),
                              // Badge salle plus compact
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[700] : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? Colors.grey[600]! : Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.home_outlined,
                                      size: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${entry.room!}',
                                      style: TextStyle(
                                        fontSize: _textSizeService.getScaledFontSize(11),
                                        color: AppColors.getTextColor(isDark, type: TextType.secondary),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (entry.teacher != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[700] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.teacher!,
                                  style: TextStyle(
                                    fontSize: _textSizeService.getScaledFontSize(11),
                                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getSubjectColor(String subject) {
    // Vérifier si la couleur est déjà en cache
    if (_subjectColorCache.containsKey(subject)) {
      return _subjectColorCache[subject]!;
    }
    
    // Palette de couleurs variées et harmonieuses
    final colors = [
      Colors.blue,        // Bleu principal
      Colors.green,       // Vert
      Colors.orange,      // Orange
      Colors.purple,      // Violet
      Colors.red,         // Rouge
      Colors.indigo,      // Indigo
      Colors.teal,        // Turquoise
      Colors.pink,        // Rose
      Colors.amber,       // Ambre
      Colors.cyan,        // Cyan
      Colors.lime,        // Citron vert
      Colors.brown,       // Marron
      Colors.blueGrey,    // Bleu gris
      Colors.deepOrange,  // Orange foncé
      Colors.deepPurple,  // Violet foncé
      Colors.lightGreen,  // Vert clair
      Colors.lightBlue,   // Bleu clair
    ];
    
    // Générer une couleur basée sur le hash du nom de la matière
    final hash = subject.toLowerCase().hashCode;
    final colorIndex = hash.abs() % colors.length;
    final selectedColor = colors[colorIndex];
    
    // Mettre en cache pour une utilisation future
    _subjectColorCache[subject] = selectedColor;
    
    return selectedColor;
  }
}

