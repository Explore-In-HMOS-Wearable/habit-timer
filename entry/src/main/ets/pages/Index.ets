import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Habit, TimerState } from '../models/HabitModel';
import { HabitService } from '../services/HabitService';
import { PreferencesService } from '../services/PreferencesService';

const TAG: string = 'IndexPage';

@Entry
@Component
struct Index {
  @State habits: Habit[] = [];
  @State selectedHabit: Habit | null = null;
  @State timerState: TimerState = {
    isRunning: false,
    currentHabitId: '',
    startTime: 0,
    elapsedTime: 0
  };
  @State currentElapsedTime: number = 0;
  @State showHabitList: boolean = true;
  private habitService: HabitService | null = null;
  private preferencesService: PreferencesService | null = null;
  private context: common.UIAbilityContext | null = null;
  private timerUpdateInterval: number = -1;
  private habitListScroller: Scroller = new Scroller();
  private timerViewScroller: Scroller = new Scroller();

  async aboutToAppear() {
    try {
      this.context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.preferencesService = new PreferencesService(this.context);
      await this.preferencesService.init();

      this.habitService = new HabitService(this.preferencesService);
      await this.habitService.init();

      this.habitService.setHabitUpdateCallback((habits: Habit[]) => {
        this.habits = habits;
      });

      this.habitService.setTimerUpdateCallback((timerState: TimerState) => {
        this.timerState = timerState;
      });

      this.habits = this.habitService.getHabits();
      this.timerState = this.habitService.getTimerState();

      this.timerUpdateInterval = setInterval(() => {
        if (this.habitService && this.timerState.isRunning) {
          this.currentElapsedTime = this.habitService.getCurrentElapsedTime();
        }
      }, 1000);

      hilog.info(0x0000, TAG, 'Page initialized successfully');
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to initialize page: ${error}`);
    }
  }

  aboutToDisappear() {
    if (this.timerUpdateInterval !== -1) {
      clearInterval(this.timerUpdateInterval);
      this.timerUpdateInterval = -1;
    }

    if (this.habitService) {
      this.habitService.destroy();
    }

    hilog.info(0x0000, TAG, 'Page destroyed');
  }

  onBackPress(): boolean | void {
    if (!this.showHabitList && !this.timerState.isRunning) {
      this.showHabitList = true;
      this.selectedHabit = null;
      hilog.info(0x0000, TAG, 'Back pressed - returning to habit list');
      return true;
    }

    if (!this.showHabitList && this.timerState.isRunning) {
      hilog.warn(0x0000, TAG, 'Back pressed - blocked (timer is running)');
      return true;
    }

    return false;
  }

  onHabitSelected(habit: Habit) {
    this.selectedHabit = habit;
    this.showHabitList = false;
    this.currentElapsedTime = 0;
    hilog.info(0x0000, TAG, `Habit selected: ${habit.name}`);
  }

  async onStartPauseClick() {
    if (!this.habitService || !this.selectedHabit) {
      return;
    }

    if (this.timerState.isRunning) {
      await this.habitService.pauseTimer();
      const updatedHabit = this.habitService.getHabitById(this.selectedHabit.id);
      if (updatedHabit) {
        this.selectedHabit = updatedHabit;
      }
    } else {
      await this.habitService.startTimer(this.selectedHabit.id);
      this.currentElapsedTime = 0;
    }
  }

  async onResetClick() {
    if (!this.habitService) {
      return;
    }

    await this.habitService.resetTimer();
    this.currentElapsedTime = 0;
  }

  onBackClick() {
    if (this.timerState.isRunning) {
      return;
    }
    this.showHabitList = true;
    this.selectedHabit = null;
  }

  formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  }

  formatDuration(seconds: number): string {
    if (seconds < 60) {
      return `${seconds}s`;
    }
    const mins = Math.floor(seconds / 60);
    if (mins < 60) {
      return `${mins}m`;
    }
    const hours = Math.floor(mins / 60);
    const remainingMins = mins % 60;
    return `${hours}h ${remainingMins}m`;
  }

  build() {
    Stack() {
      Column() {
        this.HabitListView();
      }
      .width('100%')
      .height('100%')
      .visibility(this.showHabitList ? Visibility.Visible : Visibility.Hidden)

      Column() {
        this.TimerView();
      }
      .width('100%')
      .height('100%')
      .visibility(!this.showHabitList ? Visibility.Visible : Visibility.Hidden)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }

  @Builder
  HabitListView() {
    Column() {
      Text('HabitTimer')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .margin({ top: 20, bottom: 10 })

      Text('Select a habit to start')
        .fontSize(14)
        .fontColor('#B0B0B0')
        .margin({ bottom: 20 })

      List({ scroller: this.habitListScroller, space: 12 }) {
        ForEach(this.habits, (habit: Habit) => {
          ListItem() {
            this.HabitCard(habit);
          }
        }, (habit: Habit) => habit.id)
      }
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .padding({ left: 16, right: 16, bottom: 20 })
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  HabitCard(habit: Habit) {
    Column({ space: 6 }) {
      Row() {
        Text(habit.icon)
          .fontSize(28)
          .margin({ right: 12 })

        Column({ space: 2 }) {
          Text(habit.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .alignSelf(ItemAlign.Start)

          Text(`Today: ${this.formatDuration(habit.todayDuration)}`)
            .fontSize(12)
            .fontColor('#B0B0B0')
            .alignSelf(ItemAlign.Start)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1a1a1a')
    .borderRadius(12)
    .border({ width: 2, color: habit.color })
    .onClick(() => {
      this.onHabitSelected(habit);
    })
  }

  @Builder
  TimerView() {
    List({ scroller: this.timerViewScroller }) {
      ListItem() {
        Column({ space: 20 }) {
          if (this.selectedHabit) {
            Column({ space: 8 }) {
              Text(this.selectedHabit.icon)
                .fontSize(48)

              Text(this.selectedHabit.name)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)

              Text(`Today: ${this.formatDuration(this.selectedHabit.todayDuration)}`)
                .fontSize(14)
                .fontColor('#B0B0B0')
            }
          }

          Column({ space: 10 }) {
            Text(this.formatTime(this.currentElapsedTime))
              .fontSize(56)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.timerState.isRunning ? '#00D4AA' : '#FFA500')
              .fontFamily('monospace')

            if (this.timerState.isRunning || this.currentElapsedTime > 0) {
              Text(this.timerState.isRunning ? 'Running' : 'Stopped')
                .fontSize(14)
                .fontColor(this.timerState.isRunning ? '#00D4AA' : '#FFA500')
            }
          }
          .margin({ top: 20, bottom: 20 })

          Column({ space: 16 }) {
            Button(this.timerState.isRunning ? 'Stop' : 'Start')
              .width('80%')
              .height(50)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.timerState.isRunning ? '#FFA500' : '#00D4AA')
              .borderRadius(25)
              .onClick(() => {
                this.onStartPauseClick();
              })

            Button('Reset')
              .width('80%')
              .height(50)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .backgroundColor('#333333')
              .fontColor('#FFFFFF')
              .borderRadius(25)
              .onClick(() => {
                this.onResetClick();
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ top: 20, bottom: 20 })
      }
    }
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')
  }
}
