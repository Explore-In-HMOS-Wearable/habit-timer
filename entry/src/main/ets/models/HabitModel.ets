/**
 * Habit data model for HabitTimer application
 */

/**
 * Represents a habit that can be tracked
 */
export interface Habit {
  id: string; // Unique identifier
  name: string; // Display name of the habit
  icon: string; // Icon identifier or emoji
  color: string; // Color code for UI theming
  todayDuration: number; // Time spent today in seconds
  totalDuration: number; // Total time spent all-time in seconds
  lastActive: number; // Timestamp of last activity
}

/**
 * Timer state for tracking active sessions
 */
export interface TimerState {
  isRunning: boolean; // Whether timer is currently active
  currentHabitId: string; // ID of habit being timed
  startTime: number; // Timestamp when timer started
  elapsedTime: number; // Elapsed time in current session (seconds)
}

/**
 * Daily record for habit tracking
 */
export interface DailyRecord {
  date: string; // Date in YYYY-MM-DD format
  habitId: string; // Habit ID
  duration: number; // Duration in seconds
}

/**
 * Preferences storage keys
 */
export class StorageKeys {
  static readonly HABITS = 'habits';
  static readonly TIMER_STATE = 'timer_state';
  static readonly LAST_DATE = 'last_date';
}

/**
 * Default habits configuration
 */
export const DEFAULT_HABITS: Habit[] = [
  {
    id: 'reading',
    name: 'Reading',
    icon: '📚',
    color: '#4A90E2',
    todayDuration: 0,
    totalDuration: 0,
    lastActive: 0
  },
  {
    id: 'exercise',
    name: 'Exercise',
    icon: '💪',
    color: '#E24A4A',
    todayDuration: 0,
    totalDuration: 0,
    lastActive: 0
  },
  {
    id: 'meditation',
    name: 'Meditation',
    icon: '🧘',
    color: '#9B59B6',
    todayDuration: 0,
    totalDuration: 0,
    lastActive: 0
  },
  {
    id: 'study',
    name: 'Study',
    icon: '📝',
    color: '#F39C12',
    todayDuration: 0,
    totalDuration: 0,
    lastActive: 0
  },
  {
    id: 'practice',
    name: 'Practice',
    icon: '🎸',
    color: '#1ABC9C',
    todayDuration: 0,
    totalDuration: 0,
    lastActive: 0
  }
];
