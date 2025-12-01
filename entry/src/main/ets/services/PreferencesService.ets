/**
 * PreferencesService - Handles data persistence using HarmonyOS Preferences API
 *
 * This service demonstrates how to use @kit.ArkData for simple key-value storage
 * suitable for wearable applications with limited data persistence needs.
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'PreferencesService';
const PREFERENCES_NAME: string = 'habit_timer_prefs';

/**
 * Service for managing persistent data storage
 */
export class PreferencesService {
  private preferencesInstance: preferences.Preferences | null = null;
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  /**
   * Initialize the preferences instance
   * Must be called before any read/write operations
   */
  async init(): Promise<void> {
    try {
      this.preferencesInstance = await preferences.getPreferences(this.context, PREFERENCES_NAME);
      hilog.info(0x0000, TAG, 'Preferences initialized successfully');
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(0x0000, TAG, `Failed to initialize preferences: ${businessError.message}`);
      throw new Error(`Failed to initialize preferences: ${businessError.message}`);
    }
  }

  /**
   * Save a string value to preferences
   * @param key - Storage key
   * @param value - String value to store
   */
  async putString(key: string, value: string): Promise<void> {
    if (!this.preferencesInstance) {
      hilog.error(0x0000, TAG, 'Preferences not initialized');
      return;
    }

    try {
      await this.preferencesInstance.put(key, value);
      await this.preferencesInstance.flush();
      hilog.info(0x0000, TAG, `Saved string for key: ${key}`);
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(0x0000, TAG, `Failed to save string: ${businessError.message}`);
    }
  }

  /**
   * Retrieve a string value from preferences
   * @param key - Storage key
   * @param defaultValue - Default value if key doesn't exist
   * @returns Stored string or default value
   */
  async getString(key: string, defaultValue: string): Promise<string> {
    if (!this.preferencesInstance) {
      hilog.error(0x0000, TAG, 'Preferences not initialized');
      return defaultValue;
    }

    try {
      const value = await this.preferencesInstance.get(key, defaultValue);
      return value as string;
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(0x0000, TAG, `Failed to get string: ${businessError.message}`);
      return defaultValue;
    }
  }

  /**
   * Save a number value to preferences
   * @param key - Storage key
   * @param value - Number value to store
   */
  async putNumber(key: string, value: number): Promise<void> {
    if (!this.preferencesInstance) {
      hilog.error(0x0000, TAG, 'Preferences not initialized');
      return;
    }

    try {
      await this.preferencesInstance.put(key, value);
      await this.preferencesInstance.flush();
      hilog.info(0x0000, TAG, `Saved number for key: ${key}`);
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(0x0000, TAG, `Failed to save number: ${businessError.message}`);
    }
  }

  /**
   * Retrieve a number value from preferences
   * @param key - Storage key
   * @param defaultValue - Default value if key doesn't exist
   * @returns Stored number or default value
   */
  async getNumber(key: string, defaultValue: number): Promise<number> {
    if (!this.preferencesInstance) {
      hilog.error(0x0000, TAG, 'Preferences not initialized');
      return defaultValue;
    }

    try {
      const value = await this.preferencesInstance.get(key, defaultValue);
      return value as number;
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(0x0000, TAG, `Failed to get number: ${businessError.message}`);
      return defaultValue;
    }
  }

  /**
   * Save an object as JSON string
   * @param key - Storage key
   * @param value - Object to store
   */
  async putObject<T>(key: string, value: T): Promise<void> {
    try {
      const jsonString = JSON.stringify(value);
      await this.putString(key, jsonString);
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to serialize object: ${error}`);
    }
  }

  /**
   * Retrieve an object from JSON string
   * @param key - Storage key
   * @param defaultValue - Default value if key doesn't exist
   * @returns Parsed object or default value
   */
  async getObject<T>(key: string, defaultValue: T): Promise<T> {
    try {
      const jsonString = await this.getString(key, '');
      if (jsonString === '') {
        return defaultValue;
      }
      return JSON.parse(jsonString) as T;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to parse object: ${error}`);
      return defaultValue;
    }
  }

  /**
   * Delete a value from preferences
   * @param key - Storage key to delete
   */
  async delete(key: string): Promise<void> {
    if (!this.preferencesInstance) {
      hilog.error(0x0000, TAG, 'Preferences not initialized');
      return;
    }

    try {
      await this.preferencesInstance.delete(key);
      await this.preferencesInstance.flush();
      hilog.info(0x0000, TAG, `Deleted key: ${key}`);
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(0x0000, TAG, `Failed to delete key: ${businessError.message}`);
    }
  }

  /**
   * Clear all preferences data
   */
  async clear(): Promise<void> {
    if (!this.preferencesInstance) {
      hilog.error(0x0000, TAG, 'Preferences not initialized');
      return;
    }

    try {
      await this.preferencesInstance.clear();
      await this.preferencesInstance.flush();
      hilog.info(0x0000, TAG, 'All preferences cleared');
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(0x0000, TAG, `Failed to clear preferences: ${businessError.message}`);
    }
  }
}
