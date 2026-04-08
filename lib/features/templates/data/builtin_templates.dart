import 'package:flutter/material.dart';
import 'package:biscuits/core/constants/app_constants.dart';
import 'package:biscuits/features/canvas/domain/models/canvas_config.dart';
import 'package:biscuits/features/templates/domain/entities/page_template.dart';
import 'package:biscuits/features/templates/domain/entities/template_region.dart';

/// All 24 built-in page templates.
abstract class BuiltinTemplates {
  BuiltinTemplates._();

  static const double _w = AppConstants.defaultPageWidth;
  static const double _h = AppConstants.defaultPageHeight;

  // ── Study ─────────────────────────────────────────────────────────────────

  static final cornellNotes = NoteTemplate(
    id: 'builtin_cornell_notes',
    name: 'Cornell Notes',
    description:
        'Title bar, cue column (left 1/3), notes area (right 2/3), summary strip at bottom',
    category: 'Study',
    iconEmoji: '📝',
    accentColor: const Color(0xFF4A90D9),
    background: PageTemplate.lined,
    regions: [
      TemplateRegion(
        label: 'Title',
        bounds: Rect.fromLTWH(0, 0, _w, 80),
        type: RegionType.text,
        backgroundColor: const Color(0xFF4A90D9).withOpacity(0.1),
      ),
      TemplateRegion(
        label: 'Cue Column',
        bounds: Rect.fromLTWH(0, 80, _w / 3, _h - 260),
        type: RegionType.text,
        backgroundColor: const Color(0xFFF5F8FC),
      ),
      TemplateRegion(
        label: 'Notes',
        bounds: Rect.fromLTWH(_w / 3, 80, _w * 2 / 3, _h - 260),
        type: RegionType.text,
      ),
      TemplateRegion(
        label: 'Summary',
        bounds: Rect.fromLTWH(0, _h - 180, _w, 180),
        type: RegionType.text,
        backgroundColor: const Color(0xFFE8F0FE),
      ),
    ],
  );

  static final lectureNotes = NoteTemplate(
    id: 'builtin_lecture_notes',
    name: 'Lecture Notes',
    description:
        'Date/subject header, numbered lines, margin for annotations',
    category: 'Study',
    iconEmoji: '🎓',
    accentColor: const Color(0xFF6C5CE7),
    background: PageTemplate.lined,
    regions: [
      TemplateRegion(
        label: 'Date / Subject',
        bounds: Rect.fromLTWH(0, 0, _w, 90),
        type: RegionType.text,
        backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.08),
      ),
      TemplateRegion(
        label: 'Margin',
        bounds: Rect.fromLTWH(0, 90, 100, _h - 90),
        type: RegionType.text,
        backgroundColor: const Color(0xFFF8F7FF),
      ),
      TemplateRegion(
        label: 'Content',
        bounds: Rect.fromLTWH(100, 90, _w - 100, _h - 90),
        type: RegionType.text,
      ),
    ],
  );

  static final flashcardGrid = NoteTemplate(
    id: 'builtin_flashcard_grid',
    name: 'Flashcard Grid',
    description: '2×3 grid of flashcard rectangles for Q&A study',
    category: 'Study',
    iconEmoji: '🗂️',
    accentColor: const Color(0xFFFF6B6B),
    background: PageTemplate.blank,
    regions: [
      for (int row = 0; row < 3; row++)
        for (int col = 0; col < 2; col++)
          TemplateRegion(
            label: 'Card ${row * 2 + col + 1}',
            bounds: Rect.fromLTWH(
              24 + col * (_w / 2 - 12),
              24 + row * (_h / 3 - 8),
              _w / 2 - 36,
              _h / 3 - 32,
            ),
            type: RegionType.text,
            backgroundColor: Colors.white,
          ),
    ],
  );

  static final mindMapStart = NoteTemplate(
    id: 'builtin_mind_map',
    name: 'Mind Map Start',
    description: 'Central node with 6 radiating branches',
    category: 'Study',
    iconEmoji: '🧠',
    accentColor: const Color(0xFF00B894),
    background: PageTemplate.dotted,
    regions: [
      TemplateRegion(
        label: 'Central Idea',
        bounds: Rect.fromLTWH(_w / 2 - 120, _h / 2 - 60, 240, 120),
        type: RegionType.text,
        backgroundColor: const Color(0xFF00B894).withOpacity(0.15),
      ),
      for (int i = 0; i < 6; i++)
        TemplateRegion(
          label: 'Branch ${i + 1}',
          bounds: Rect.fromLTWH(
            _w / 2 - 80 + 300 * (i.isEven ? -1.0 : 1.0),
            100 + i * 250.0,
            160,
            80,
          ),
          type: RegionType.text,
        ),
    ],
  );

  static final readingNotes = NoteTemplate(
    id: 'builtin_reading_notes',
    name: 'Reading Notes',
    description: 'Book title, chapter, key quotes column, reflections column',
    category: 'Study',
    iconEmoji: '📖',
    accentColor: const Color(0xFFA29BFE),
    background: PageTemplate.lined,
    regions: [
      TemplateRegion(
        label: 'Book Title / Chapter',
        bounds: Rect.fromLTWH(0, 0, _w, 100),
        type: RegionType.text,
        backgroundColor: const Color(0xFFF0EEFF),
      ),
      TemplateRegion(
        label: 'Key Quotes',
        bounds: Rect.fromLTWH(0, 100, _w / 2, _h - 100),
        type: RegionType.text,
        backgroundColor: const Color(0xFFFFF9E6),
      ),
      TemplateRegion(
        label: 'Reflections',
        bounds: Rect.fromLTWH(_w / 2, 100, _w / 2, _h - 100),
        type: RegionType.text,
      ),
    ],
  );

  // ── Planning ──────────────────────────────────────────────────────────────

  static final weeklyPlanner = NoteTemplate(
    id: 'builtin_weekly_planner',
    name: 'Weekly Planner',
    description: '7-day grid with time slots, priorities sidebar',
    category: 'Planning',
    iconEmoji: '📅',
    accentColor: const Color(0xFF0984E3),
    background: PageTemplate.blank,
    regions: [
      TemplateRegion(
        label: 'Priorities',
        bounds: Rect.fromLTWH(0, 0, 200, _h),
        type: RegionType.text,
        backgroundColor: const Color(0xFFF0F7FF),
      ),
      for (int day = 0; day < 7; day++)
        TemplateRegion(
          label: [
            'Mon',
            'Tue',
            'Wed',
            'Thu',
            'Fri',
            'Sat',
            'Sun'
          ][day],
          bounds: Rect.fromLTWH(
            200,
            day * (_h / 7),
            _w - 200,
            _h / 7,
          ),
          type: RegionType.text,
          backgroundColor:
              day >= 5 ? const Color(0xFFFFF8E1) : Colors.transparent,
        ),
    ],
  );

  static final dailyPlanner = NoteTemplate(
    id: 'builtin_daily_planner',
    name: 'Daily Planner',
    description: 'Schedule (hourly), to-do list, notes, gratitude section',
    category: 'Planning',
    iconEmoji: '☀️',
    accentColor: const Color(0xFFFFA502),
    background: PageTemplate.blank,
    regions: [
      TemplateRegion(
        label: 'Schedule',
        bounds: Rect.fromLTWH(0, 0, _w / 2, _h * 0.7),
        type: RegionType.text,
        backgroundColor: const Color(0xFFF7F7F7),
      ),
      TemplateRegion(
        label: 'To-Do',
        bounds: Rect.fromLTWH(_w / 2, 0, _w / 2, _h * 0.4),
        type: RegionType.text,
      ),
      TemplateRegion(
        label: 'Notes',
        bounds: Rect.fromLTWH(_w / 2, _h * 0.4, _w / 2, _h * 0.3),
        type: RegionType.text,
        backgroundColor: const Color(0xFFFFF3E0),
      ),
      TemplateRegion(
        label: 'Gratitude',
        bounds: Rect.fromLTWH(0, _h * 0.7, _w, _h * 0.3),
        type: RegionType.text,
        backgroundColor: const Color(0xFFFFF8E1),
      ),
    ],
  );

  static final monthlyCalendar = NoteTemplate(
    id: 'builtin_monthly_calendar',
    name: 'Monthly Calendar',
    description: 'Grid calendar with notes area below',
    category: 'Planning',
    iconEmoji: '🗓️',
    accentColor: const Color(0xFFE84393),
    background: PageTemplate.blank,
    regions: [
      TemplateRegion(
        label: 'Month Title',
        bounds: Rect.fromLTWH(0, 0, _w, 80),
        type: RegionType.text,
        backgroundColor: const Color(0xFFE84393).withOpacity(0.1),
      ),
      // 5 weeks × 7 days grid
      for (int week = 0; week < 5; week++)
        for (int day = 0; day < 7; day++)
          TemplateRegion(
            label: '${week * 7 + day + 1}',
            bounds: Rect.fromLTWH(
              day * (_w / 7),
              80 + week * 240,
              _w / 7,
              240,
            ),
            type: RegionType.text,
          ),
      TemplateRegion(
        label: 'Monthly Notes',
        bounds: Rect.fromLTWH(0, 80 + 5 * 240, _w, _h - (80 + 5 * 240)),
        type: RegionType.text,
        backgroundColor: const Color(0xFFFDF2F8),
      ),
    ],
  );

  static final goalTracker = NoteTemplate(
    id: 'builtin_goal_tracker',
    name: 'Goal Tracker',
    description: 'Goal header, milestones timeline, progress bar, reflections',
    category: 'Planning',
    iconEmoji: '🎯',
    accentColor: const Color(0xFF00CEC9),
    background: PageTemplate.blank,
    regions: [
      TemplateRegion(
        label: 'Goal',
        bounds: Rect.fromLTWH(0, 0, _w, 120),
        type: RegionType.text,
        backgroundColor: const Color(0xFF00CEC9).withOpacity(0.1),
      ),
      TemplateRegion(
        label: 'Progress',
        bounds: Rect.fromLTWH(0, 120, _w, 60),
        type: RegionType.widget,
      ),
      TemplateRegion(
        label: 'Milestones',
        bounds: Rect.fromLTWH(0, 180, _w, _h * 0.4),
        type: RegionType.text,
      ),
      TemplateRegion(
        label: 'Reflections',
        bounds: Rect.fromLTWH(0, 180 + _h * 0.4, _w, _h - 180 - _h * 0.4),
        type: RegionType.text,
        backgroundColor: const Color(0xFFE0F7FA),
      ),
    ],
  );

  static final kanbanBoard = NoteTemplate(
    id: 'builtin_kanban',
    name: 'Kanban Board',
    description: '3 columns: To Do, In Progress, Done',
    category: 'Planning',
    iconEmoji: '📋',
    accentColor: const Color(0xFF636E72),
    background: PageTemplate.blank,
    regions: [
      TemplateRegion(
        label: 'To Do',
        bounds: Rect.fromLTWH(0, 0, _w / 3, _h),
        type: RegionType.text,
        backgroundColor: const Color(0xFFFFE8E8),
      ),
      TemplateRegion(
        label: 'In Progress',
        bounds: Rect.fromLTWH(_w / 3, 0, _w / 3, _h),
        type: RegionType.text,
        backgroundColor: const Color(0xFFFFF3E0),
      ),
      TemplateRegion(
        label: 'Done',
        bounds: Rect.fromLTWH(_w * 2 / 3, 0, _w / 3, _h),
        type: RegionType.text,
        backgroundColor: const Color(0xFFE8F5E9),
      ),
    ],
  );

  // ── Creative ──────────────────────────────────────────────────────────────

  static final storyboard = NoteTemplate(
    id: 'builtin_storyboard',
    name: 'Storyboard',
    description: '6 panels (2×3) with caption areas below each',
    category: 'Creative',
    iconEmoji: '🎬',
    accentColor: const Color(0xFFD63031),
    background: PageTemplate.blank,
    regions: [
      for (int row = 0; row < 3; row++)
        for (int col = 0; col < 2; col++) ...[
          TemplateRegion(
            label: 'Panel ${row * 2 + col + 1}',
            bounds: Rect.fromLTWH(
              24 + col * (_w / 2),
              24 + row * (_h / 3),
              _w / 2 - 48,
              _h / 3 - 80,
            ),
            type: RegionType.drawing,
            backgroundColor: Colors.white,
          ),
          TemplateRegion(
            label: 'Caption ${row * 2 + col + 1}',
            bounds: Rect.fromLTWH(
              24 + col * (_w / 2),
              24 + row * (_h / 3) + _h / 3 - 80,
              _w / 2 - 48,
              56,
            ),
            type: RegionType.text,
            backgroundColor: const Color(0xFFF5F5F5),
          ),
        ],
    ],
  );

  static final moodBoard = NoteTemplate(
    id: 'builtin_mood_board',
    name: 'Mood Board',
    description: 'Free-form regions for images/text/colors',
    category: 'Creative',
    iconEmoji: '🎨',
    accentColor: const Color(0xFFE17055),
    background: PageTemplate.blank,
    regions: [
      TemplateRegion(
        label: 'Visual 1',
        bounds: Rect.fromLTWH(20, 20, _w * 0.55, _h * 0.4),
        type: RegionType.image,
        backgroundColor: const Color(0xFFFADADD),
      ),
      TemplateRegion(
        label: 'Visual 2',
        bounds: Rect.fromLTWH(_w * 0.58, 20, _w * 0.4, _h * 0.25),
        type: RegionType.image,
        backgroundColor: const Color(0xFFE0F2F1),
      ),
      TemplateRegion(
        label: 'Text',
        bounds: Rect.fromLTWH(_w * 0.58, _h * 0.28, _w * 0.4, _h * 0.15),
        type: RegionType.text,
      ),
      TemplateRegion(
        label: 'Colors',
        bounds: Rect.fromLTWH(20, _h * 0.44, _w * 0.35, _h * 0.25),
        type: RegionType.drawing,
        backgroundColor: const Color(0xFFFFF9C4),
      ),
      TemplateRegion(
        label: 'Visual 3',
        bounds: Rect.fromLTWH(_w * 0.38, _h * 0.44, _w * 0.6, _h * 0.54),
        type: RegionType.image,
        backgroundColor: const Color(0xFFE8EAF6),
      ),
      TemplateRegion(
        label: 'Notes',
        bounds: Rect.fromLTWH(20, _h * 0.72, _w * 0.35, _h * 0.26),
        type: RegionType.text,
      ),
    ],
  );

  static final characterSheet = NoteTemplate(
    id: 'builtin_character_sheet',
    name: 'Character Sheet',
    description: 'Portrait area, stats grid, backstory section',
    category: 'Creative',
    iconEmoji: '🧙',
    accentColor: const Color(0xFF6C5CE7),
    background: PageTemplate.blank,
    regions: [
      TemplateRegion(
        label: 'Portrait',
        bounds: Rect.fromLTWH(20, 20, _w * 0.4, _h * 0.35),
        type: RegionType.drawing,
        backgroundColor: const Color(0xFFF0EEFF),
      ),
      TemplateRegion(
        label: 'Name & Class',
        bounds: Rect.fromLTWH(_w * 0.44, 20, _w * 0.54, 80),
        type: RegionType.text,
        backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.1),
      ),
      TemplateRegion(
        label: 'Stats',
        bounds: Rect.fromLTWH(_w * 0.44, 110, _w * 0.54, _h * 0.35 - 90),
        type: RegionType.text,
      ),
      TemplateRegion(
        label: 'Abilities',
        bounds: Rect.fromLTWH(20, _h * 0.38, _w / 2 - 10, _h * 0.3),
        type: RegionType.text,
        backgroundColor: const Color(0xFFF8F7FF),
      ),
      TemplateRegion(
        label: 'Inventory',
        bounds: Rect.fromLTWH(_w / 2 + 10, _h * 0.38, _w / 2 - 30, _h * 0.3),
        type: RegionType.text,
      ),
      TemplateRegion(
        label: 'Backstory',
        bounds: Rect.fromLTWH(20, _h * 0.7, _w - 40, _h * 0.28),
        type: RegionType.text,
        backgroundColor: const Color(0xFFFFF3E0),
      ),
    ],
  );

  static final recipeCard = NoteTemplate(
    id: 'builtin_recipe_card',
    name: 'Recipe Card',
    description: 'Ingredients list, steps area, photo placeholder, rating',
    category: 'Creative',
    iconEmoji: '🍳',
    accentColor: const Color(0xFFF39C12),
    background: PageTemplate.blank,
    regions: [
      TemplateRegion(
        label: 'Recipe Name',
        bounds: Rect.fromLTWH(0, 0, _w, 100),
        type: RegionType.text,
        backgroundColor: const Color(0xFFF39C12).withOpacity(0.1),
      ),
      TemplateRegion(
        label: 'Photo',
        bounds: Rect.fromLTWH(_w * 0.55, 110, _w * 0.43, _h * 0.3),
        type: RegionType.image,
        backgroundColor: const Color(0xFFF5F5F5),
      ),
      TemplateRegion(
        label: 'Ingredients',
        bounds: Rect.fromLTWH(20, 110, _w * 0.52, _h * 0.3),
        type: RegionType.text,
        backgroundColor: const Color(0xFFFFF8E1),
      ),
      TemplateRegion(
        label: 'Steps',
        bounds: Rect.fromLTWH(20, _h * 0.35 + 100, _w - 40, _h * 0.5),
        type: RegionType.text,
      ),
      TemplateRegion(
        label: 'Rating',
        bounds: Rect.fromLTWH(20, _h * 0.88, _w - 40, _h * 0.1),
        type: RegionType.widget,
        backgroundColor: const Color(0xFFFFF3E0),
      ),
    ],
  );

  static final musicSheet = NoteTemplate(
    id: 'builtin_music_sheet',
    name: 'Music Sheet',
    description: 'Staff lines with clef, time signature areas',
    category: 'Creative',
    iconEmoji: '🎵',
    accentColor: const Color(0xFF2D3436),
    background: PageTemplate.blank,
    regions: [
      TemplateRegion(
        label: 'Title',
        bounds: Rect.fromLTWH(0, 0, _w, 80),
        type: RegionType.text,
      ),
      for (int staff = 0; staff < 8; staff++)
        TemplateRegion(
          label: 'Staff ${staff + 1}',
          bounds: Rect.fromLTWH(
            80,
            100 + staff * ((_h - 100) / 8),
            _w - 100,
            ((_h - 100) / 8) - 20,
          ),
          type: RegionType.drawing,
        ),
    ],
  );

  // ── Productivity ──────────────────────────────────────────────────────────

  static final meetingNotes = NoteTemplate(
    id: 'builtin_meeting_notes',
    name: 'Meeting Notes',
    description: 'Attendees, agenda, discussion, action items, deadlines',
    category: 'Productivity',
    iconEmoji: '💼',
    accentColor: const Color(0xFF0984E3),
    background: PageTemplate.lined,
    regions: [
      TemplateRegion(
        label: 'Meeting Title / Date',
        bounds: Rect.fromLTWH(0, 0, _w, 80),
        type: RegionType.text,
        backgroundColor: const Color(0xFF0984E3).withOpacity(0.08),
      ),
      TemplateRegion(
        label: 'Attendees',
        bounds: Rect.fromLTWH(0, 80, _w, 100),
        type: RegionType.text,
        backgroundColor: const Color(0xFFF5F8FC),
      ),
      TemplateRegion(
        label: 'Agenda',
        bounds: Rect.fromLTWH(0, 180, _w / 2, _h * 0.35),
        type: RegionType.text,
      ),
      TemplateRegion(
        label: 'Discussion',
        bounds: Rect.fromLTWH(_w / 2, 180, _w / 2, _h * 0.35),
        type: RegionType.text,
      ),
      TemplateRegion(
        label: 'Action Items',
        bounds: Rect.fromLTWH(0, 180 + _h * 0.35, _w, _h - 180 - _h * 0.35),
        type: RegionType.text,
        backgroundColor: const Color(0xFFE8F5E9),
      ),
    ],
  );

  static final projectPlan = NoteTemplate(
    id: 'builtin_project_plan',
    name: 'Project Plan',
    description: 'Gantt-style timeline bars, milestones, team assignments',
    category: 'Productivity',
    iconEmoji: '📊',
    accentColor: const Color(0xFF00B894),
    background: PageTemplate.grid,
    defaultConfig: const CanvasConfig(gridSpacing: 40),
    regions: [
      TemplateRegion(
        label: 'Project Title',
        bounds: Rect.fromLTWH(0, 0, _w, 80),
        type: RegionType.text,
        backgroundColor: const Color(0xFF00B894).withOpacity(0.1),
      ),
      TemplateRegion(
        label: 'Timeline',
        bounds: Rect.fromLTWH(200, 80, _w - 200, _h * 0.55),
        type: RegionType.drawing,
      ),
      TemplateRegion(
        label: 'Tasks',
        bounds: Rect.fromLTWH(0, 80, 200, _h * 0.55),
        type: RegionType.text,
        backgroundColor: const Color(0xFFF0FFF4),
      ),
      TemplateRegion(
        label: 'Team & Notes',
        bounds: Rect.fromLTWH(0, _h * 0.65, _w, _h * 0.35),
        type: RegionType.text,
      ),
    ],
  );

  static final swotAnalysis = NoteTemplate(
    id: 'builtin_swot',
    name: 'SWOT Analysis',
    description: '2×2 grid: Strengths, Weaknesses, Opportunities, Threats',
    category: 'Productivity',
    iconEmoji: '🔍',
    accentColor: const Color(0xFFFFA502),
    background: PageTemplate.blank,
    regions: [
      TemplateRegion(
        label: 'Strengths',
        bounds: Rect.fromLTWH(0, 0, _w / 2, _h / 2),
        type: RegionType.text,
        backgroundColor: const Color(0xFFE8F5E9),
      ),
      TemplateRegion(
        label: 'Weaknesses',
        bounds: Rect.fromLTWH(_w / 2, 0, _w / 2, _h / 2),
        type: RegionType.text,
        backgroundColor: const Color(0xFFFFEBEE),
      ),
      TemplateRegion(
        label: 'Opportunities',
        bounds: Rect.fromLTWH(0, _h / 2, _w / 2, _h / 2),
        type: RegionType.text,
        backgroundColor: const Color(0xFFE3F2FD),
      ),
      TemplateRegion(
        label: 'Threats',
        bounds: Rect.fromLTWH(_w / 2, _h / 2, _w / 2, _h / 2),
        type: RegionType.text,
        backgroundColor: const Color(0xFFFFF3E0),
      ),
    ],
  );

  static final eisenhowerMatrix = NoteTemplate(
    id: 'builtin_eisenhower',
    name: 'Eisenhower Matrix',
    description: '2×2: Urgent+Important, Not Urgent+Important, etc.',
    category: 'Productivity',
    iconEmoji: '⚡',
    accentColor: const Color(0xFFE84393),
    background: PageTemplate.blank,
    regions: [
      TemplateRegion(
        label: 'Do (Urgent + Important)',
        bounds: Rect.fromLTWH(0, 0, _w / 2, _h / 2),
        type: RegionType.text,
        backgroundColor: const Color(0xFFFFCDD2),
      ),
      TemplateRegion(
        label: 'Schedule (Important)',
        bounds: Rect.fromLTWH(_w / 2, 0, _w / 2, _h / 2),
        type: RegionType.text,
        backgroundColor: const Color(0xFFC8E6C9),
      ),
      TemplateRegion(
        label: 'Delegate (Urgent)',
        bounds: Rect.fromLTWH(0, _h / 2, _w / 2, _h / 2),
        type: RegionType.text,
        backgroundColor: const Color(0xFFBBDEFB),
      ),
      TemplateRegion(
        label: 'Eliminate',
        bounds: Rect.fromLTWH(_w / 2, _h / 2, _w / 2, _h / 2),
        type: RegionType.text,
        backgroundColor: const Color(0xFFF5F5F5),
      ),
    ],
  );

  static final habitTracker = NoteTemplate(
    id: 'builtin_habit_tracker',
    name: 'Habit Tracker',
    description: '31-day grid with habit rows, streak counter',
    category: 'Productivity',
    iconEmoji: '✅',
    accentColor: const Color(0xFF2ECC71),
    background: PageTemplate.blank,
    regions: [
      TemplateRegion(
        label: 'Month',
        bounds: Rect.fromLTWH(0, 0, _w, 80),
        type: RegionType.text,
        backgroundColor: const Color(0xFF2ECC71).withOpacity(0.1),
      ),
      TemplateRegion(
        label: 'Habit Names',
        bounds: Rect.fromLTWH(0, 80, 200, _h - 80),
        type: RegionType.text,
        backgroundColor: const Color(0xFFE8F5E9),
      ),
      TemplateRegion(
        label: 'Tracker Grid',
        bounds: Rect.fromLTWH(200, 80, _w - 200, _h - 80),
        type: RegionType.drawing,
      ),
    ],
  );

  // ── Special ───────────────────────────────────────────────────────────────

  static final blankGrid = NoteTemplate(
    id: 'builtin_blank_grid',
    name: 'Blank with Grid',
    description: 'Clean grid background for sketching',
    category: 'Special',
    iconEmoji: '📐',
    accentColor: Colors.blueGrey,
    background: PageTemplate.grid,
    regions: const [],
  );

  static final dotGrid = NoteTemplate(
    id: 'builtin_dot_grid',
    name: 'Dot Grid',
    description: 'Bullet journal style dot grid',
    category: 'Special',
    iconEmoji: '⬤',
    accentColor: Colors.grey,
    background: PageTemplate.dotted,
    regions: const [],
  );

  static final isometricGrid = NoteTemplate(
    id: 'builtin_isometric',
    name: 'Isometric Grid',
    description: 'For 3D sketching and technical drawing',
    category: 'Special',
    iconEmoji: '🔷',
    accentColor: const Color(0xFF74B9FF),
    background: PageTemplate.dotted,
    defaultConfig: const CanvasConfig(dotSpacing: 24),
    regions: const [],
  );

  static final sheetMusic = NoteTemplate(
    id: 'builtin_sheet_music',
    name: 'Sheet Music',
    description: 'Musical staff lines for composition',
    category: 'Special',
    iconEmoji: '🎼',
    accentColor: const Color(0xFF2D3436),
    background: PageTemplate.blank,
    regions: [
      for (int staff = 0; staff < 10; staff++)
        TemplateRegion(
          label: 'Staff ${staff + 1}',
          bounds: Rect.fromLTWH(
            60,
            40 + staff * (_h / 10),
            _w - 80,
            _h / 10 - 20,
          ),
          type: RegionType.drawing,
        ),
    ],
  );

  /// All built-in templates.
  static final List<NoteTemplate> all = [
    // Study
    cornellNotes,
    lectureNotes,
    flashcardGrid,
    mindMapStart,
    readingNotes,
    // Planning
    weeklyPlanner,
    dailyPlanner,
    monthlyCalendar,
    goalTracker,
    kanbanBoard,
    // Creative
    storyboard,
    moodBoard,
    characterSheet,
    recipeCard,
    musicSheet,
    // Productivity
    meetingNotes,
    projectPlan,
    swotAnalysis,
    eisenhowerMatrix,
    habitTracker,
    // Special
    blankGrid,
    dotGrid,
    isometricGrid,
    sheetMusic,
  ];

  static final List<String> categories = [
    'Study',
    'Planning',
    'Creative',
    'Productivity',
    'Special',
  ];
}
