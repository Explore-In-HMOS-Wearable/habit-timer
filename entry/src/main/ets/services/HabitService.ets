/**
 * HabitService - Core business logic for habit tracking and timer management
 *
 * This service demonstrates:
 * - Timer/stopwatch implementation with setInterval
 * - State management for multiple habits
 * - Daily reset logic
 * - Data persistence integration
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { DEFAULT_HABITS, Habit, StorageKeys, TimerState } from '../models/HabitModel';
import { PreferencesService } from './PreferencesService';

const TAG: string = 'HabitService';

/**
 * Callback type for habit updates
 */
export type HabitUpdateCallback = (habits: Habit[]) => void;

export type TimerUpdateCallback = (timerState: TimerState) => void;

/**
 * Service for managing habits and timer functionality
 */
export class HabitService {
  private habits: Habit[] = [];
  private timerState: TimerState = {
    isRunning: false,
    currentHabitId: '',
    startTime: 0,
    elapsedTime: 0
  };
  private timerInterval: number = -1;
  private preferencesService: PreferencesService;
  private habitUpdateCallback: HabitUpdateCallback | null = null;
  private timerUpdateCallback: TimerUpdateCallback | null = null;

  constructor(preferencesService: PreferencesService) {
    this.preferencesService = preferencesService;
  }

  /**
   * Initialize service - load habits from storage
   */
  async init(): Promise<void> {
    try {
      // Load habits from preferences or use defaults
      const savedHabits = await this.preferencesService.getObject<Habit[]>(StorageKeys.HABITS, []);

      if (savedHabits.length > 0) {
        this.habits = savedHabits;
        hilog.info(0x0000, TAG, `Loaded ${savedHabits.length} habits from storage`);
      } else {
        this.habits = Array.from(DEFAULT_HABITS);
        await this.saveHabits();
        hilog.info(0x0000, TAG, 'Initialized with default habits');
      }

      // Check if we need to reset daily stats
      await this.checkDailyReset();

      // Load timer state if exists
      const savedTimerState = await this.preferencesService.getObject<TimerState>(
        StorageKeys.TIMER_STATE,
        this.timerState
      );

      // Don't restore running state - always start fresh
      if (savedTimerState.currentHabitId) {
        this.timerState = {
          isRunning: false,
          currentHabitId: savedTimerState.currentHabitId,
          startTime: savedTimerState.startTime,
          elapsedTime: savedTimerState.elapsedTime
        };
      }

    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to initialize service: ${error}`);
      this.habits = Array.from(DEFAULT_HABITS);
    }
  }

  /**
   * Get all habits
   */
  getHabits(): Habit[] {
    return Array.from(this.habits);
  }

  /**
   * Get habit by ID
   */
  getHabitById(id: string): Habit | null {
    const habit = this.habits.find(h => h.id === id);
    if (!habit) {
      return null;
    }
    return {
      id: habit.id,
      name: habit.name,
      icon: habit.icon,
      color: habit.color,
      todayDuration: habit.todayDuration,
      totalDuration: habit.totalDuration,
      lastActive: habit.lastActive
    };
  }

  /**
   * Get current timer state
   */
  getTimerState(): TimerState {
    return {
      isRunning: this.timerState.isRunning,
      currentHabitId: this.timerState.currentHabitId,
      startTime: this.timerState.startTime,
      elapsedTime: this.timerState.elapsedTime
    };
  }

  /**
   * Start timer for a habit
   */
  async startTimer(habitId: string): Promise<void> {
    if (this.timerState.isRunning) {
      hilog.warn(0x0000, TAG, 'Timer already running');
      return;
    }

    const habit = this.habits.find(h => h.id === habitId);
    if (!habit) {
      hilog.error(0x0000, TAG, `Habit not found: ${habitId}`);
      return;
    }

    this.timerState = {
      isRunning: true,
      currentHabitId: habitId,
      startTime: Date.now(),
      elapsedTime: 0
    };

    // Start interval to update timer every second
    this.timerInterval = setInterval(() => {
      this.updateTimer();
    }, 1000);

    await this.saveTimerState();
    this.notifyTimerUpdate();

    hilog.info(0x0000, TAG, `Timer started for habit: ${habitId}`);
  }

  /**
   * Pause the current timer
   */
  async pauseTimer(): Promise<void> {
    if (!this.timerState.isRunning) {
      hilog.warn(0x0000, TAG, 'Timer is not running');
      return;
    }

    // Calculate final elapsed time
    const now = Date.now();
    const sessionDuration = Math.floor((now - this.timerState.startTime) / 1000);
    this.timerState.elapsedTime += sessionDuration;

    // Update habit duration
    const habit = this.habits.find(h => h.id === this.timerState.currentHabitId);
    if (habit) {
      habit.todayDuration += sessionDuration;
      habit.totalDuration += sessionDuration;
      habit.lastActive = now;
      await this.saveHabits();
      this.notifyHabitUpdate();
    }

    // Stop interval
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval);
      this.timerInterval = -1;
    }

    this.timerState.isRunning = false;
    await this.saveTimerState();
    this.notifyTimerUpdate();

    hilog.info(0x0000, TAG, `Timer paused. Session duration: ${sessionDuration}s`);
  }

  /**
   * Reset the current timer
   */
  async resetTimer(): Promise<void> {
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval);
      this.timerInterval = -1;
    }

    this.timerState = {
      isRunning: false,
      currentHabitId: '',
      startTime: 0,
      elapsedTime: 0
    };

    await this.saveTimerState();
    this.notifyTimerUpdate();

    hilog.info(0x0000, TAG, 'Timer reset');
  }

  /**
   * Get current elapsed time in seconds
   */
  getCurrentElapsedTime(): number {
    if (!this.timerState.isRunning) {
      return this.timerState.elapsedTime;
    }

    const now = Date.now();
    const currentSessionTime = Math.floor((now - this.timerState.startTime) / 1000);
    return this.timerState.elapsedTime + currentSessionTime;
  }

  /**
   * Register callback for habit updates
   */
  setHabitUpdateCallback(callback: HabitUpdateCallback): void {
    this.habitUpdateCallback = callback;
  }

  /**
   * Register callback for timer updates
   */
  setTimerUpdateCallback(callback: TimerUpdateCallback): void {
    this.timerUpdateCallback = callback;
  }

  /**
   * Cleanup resources
   */
  destroy(): void {
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval);
      this.timerInterval = -1;
    }
    hilog.info(0x0000, TAG, 'Service destroyed');
  }

  /**
   * Check if we need to reset daily statistics
   */
  private async checkDailyReset(): Promise<void> {
    const today = this.getTodayDateString();
    const lastDate = await this.preferencesService.getString(StorageKeys.LAST_DATE, '');

    if (lastDate !== today) {
      hilog.info(0x0000, TAG, `New day detected, resetting daily stats. Last: ${lastDate}, Today: ${today}`);

      // Reset today's duration for all habits
      for (let i = 0; i < this.habits.length; i++) {
        this.habits[i].todayDuration = 0;
      }

      await this.preferencesService.putString(StorageKeys.LAST_DATE, today);
      await this.saveHabits();
    }
  }

  /**
   * Get today's date as YYYY-MM-DD string
   */
  private getTodayDateString(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * Update timer elapsed time
   */
  private updateTimer(): void {
    if (!this.timerState.isRunning) {
      return;
    }

    // Notify UI about timer update
    this.notifyTimerUpdate();

    // Auto-save every 10 seconds
    const totalElapsed = this.getCurrentElapsedTime();
    if (totalElapsed % 10 === 0 && totalElapsed > 0) {
      this.autoSaveProgress();
    }
  }

  /**
   * Auto-save progress while timer is running
   */
  private async autoSaveProgress(): Promise<void> {
    if (!this.timerState.isRunning) {
      return;
    }

    const habit = this.habits.find(h => h.id === this.timerState.currentHabitId);
    if (habit) {
      const currentSessionTime = Math.floor((Date.now() - this.timerState.startTime) / 1000);
      const tempTodayDuration = habit.todayDuration + currentSessionTime;

      hilog.info(0x0000, TAG, `Auto-save: ${habit.name} - ${tempTodayDuration}s today`);
      // Note: We don't actually update the habit duration yet, just log for safety
      // Duration is updated when timer is paused
    }
  }

  /**
   * Save habits to preferences
   */
  private async saveHabits(): Promise<void> {
    try {
      await this.preferencesService.putObject(StorageKeys.HABITS, this.habits);
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to save habits: ${error}`);
    }
  }

  /**
   * Save timer state to preferences
   */
  private async saveTimerState(): Promise<void> {
    try {
      await this.preferencesService.putObject(StorageKeys.TIMER_STATE, this.timerState);
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to save timer state: ${error}`);
    }
  }

  /**
   * Notify listeners of habit updates
   */
  private notifyHabitUpdate(): void {
    if (this.habitUpdateCallback) {
      this.habitUpdateCallback(Array.from(this.habits));
    }
  }

  /**
   * Notify listeners of timer updates
   */
  private notifyTimerUpdate(): void {
    if (this.timerUpdateCallback) {
      this.timerUpdateCallback({
        isRunning: this.timerState.isRunning,
        currentHabitId: this.timerState.currentHabitId,
        startTime: this.timerState.startTime,
        elapsedTime: this.timerState.elapsedTime
      });
    }
  }
}
