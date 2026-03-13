import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { Record } from './Record'

const PREFERENCES_NAME = 'spend_track_prefs'
const RECORDS_KEY = 'records'

export class RecordStore {
  private static instance: RecordStore
  private preferences: preferences.Preferences | null = null
  private initPromise: Promise<void> | null = null

  private constructor() {}

  static getInstance(): RecordStore {
    if (!RecordStore.instance) {
      RecordStore.instance = new RecordStore()
    }
    return RecordStore.instance
  }

  // 初始化 Preferences
  async init(context: common.UIAbilityContext) {
    if (this.preferences) {
      return
    }
    if (this.initPromise) {
      await this.initPromise
      return
    }

    this.initPromise = (async () => {
      try {
        this.preferences = await preferences.getPreferences(context, PREFERENCES_NAME)
      } catch (error) {
        console.error('初始化本地存储失败:', error)
      } finally {
        this.initPromise = null
      }
    })()

    await this.initPromise
  }

  private async waitForInitIfNeeded(): Promise<void> {
    if (this.preferences) {
      return
    }
    if (this.initPromise) {
      await this.initPromise
    }
  }

  // 获取所有记录
  async getAllRecords(): Promise<Record[]> {
    await this.waitForInitIfNeeded()
    if (!this.preferences) {
      return []
    }
    try {
      const jsonStr = await this.preferences.get(RECORDS_KEY, '[]') as string
      return JSON.parse(jsonStr) as Record[]
    } catch (error) {
      console.error('读取记账记录失败:', error)
      return []
    }
  }

  // 保存所有记录
  async saveRecords(records: Record[]): Promise<void> {
    await this.waitForInitIfNeeded()
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(RECORDS_KEY, JSON.stringify(records))
      await this.preferences.flush()
    } catch (error) {
      console.error('保存记账记录失败:', error)
    }
  }

  // 添加记录
  async addRecord(record: Record): Promise<void> {
    const records = await this.getAllRecords()
    records.push(record)
    await this.saveRecords(records)
  }

  // 删除记录
  async deleteRecord(id: string): Promise<void> {
    const records = await this.getAllRecords()
    const filtered = records.filter(r => r.id !== id)
    await this.saveRecords(filtered)
  }

  // 计算总资产
  async calculateBalance(): Promise<number> {
    const records = await this.getAllRecords()
    let balance = 0
    for (const record of records) {
      if (record.type === 'income') {
        balance += record.amount
      } else {
        balance -= record.amount
      }
    }
    return balance
  }
}
