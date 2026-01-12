/**
 * Habit data model for HabitTimer application
 */

/**
 * Represents a habit that can be tracked
 */
export interface Habit {
  id: string;
  name: string;
  icon: string;
  color: string;
  todayDuration: number;
  totalDuration: number;
  lastActive: number;
}

/**
 * Timer state for tracking active sessions
 */
export interface TimerState {
  isRunning: boolean;
  currentHabitId: string;
  startTime: number;
  elapsedTime: number;
}

/**
 * Daily record for habit tracking
 */
export interface DailyRecord {
  date: string;
  habitId: string;
  duration: number;
}

/**
 * Preferences storage keys
 */
export class StorageKeys {
  static readonly HABITS = 'habits';
  static readonly TIMER_STATE = 'timer_state';
  static readonly LAST_DATE = 'last_date';
}

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
