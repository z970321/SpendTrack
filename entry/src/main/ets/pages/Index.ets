import { Record } from '../common/Record'
import { RecordStore } from '../common/RecordStore'
import { CategoryItem, ExpenseCategories, IncomeCategories, getCategoryById } from '../common/Category'

class GroupedRecords {
  date: string
  dateDisplay: string
  records: Record[]

  constructor(date: string, dateDisplay: string, records: Record[]) {
    this.date = date
    this.dateDisplay = dateDisplay
    this.records = records
  }
}

class SummaryData {
  income: number
  expense: number
  net: number

  constructor(income: number, expense: number) {
    this.income = income
    this.expense = expense
    this.net = income - expense
  }
}

@Component
struct HomeIcon {
  @Prop isSelected: boolean = false

  build() {
    Column() {
      Polygon()
        .width(20)
        .height(10)
        .points([[10, 0], [0, 10], [20, 10]])
        .fill(this.isSelected ? '#36D1DC' : '#999999')

      Rect()
        .width(16)
        .height(10)
        .fill(this.isSelected ? '#36D1DC' : '#999999')
        .margin({ top: -1 })
    }
    .justifyContent(FlexAlign.Center)
    .width(24)
    .height(24)
  }
}

@Component
struct RecordIcon {
  @Prop isSelected: boolean = false

  build() {
    Stack() {
      Rect()
        .width(18)
        .height(22)
        .radius(2)
        .fill(this.isSelected ? '#36D1DC' : '#999999')

      Column() {
        Rect().width(10).height(1).fill('#FFFFFF').margin({ bottom: 2 })
        Rect().width(10).height(1).fill('#FFFFFF').margin({ bottom: 2 })
        Rect().width(10).height(1).fill('#FFFFFF')
      }

      Text('+')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ top: 1 })
    }
    .width(24)
    .height(24)
  }
}

@Entry
@Component
struct Index {
  @State activeTab: 'home' | 'record' = 'home'
  @State totalBalance: number = 0
  @State allRecords: Record[] = []
  @State groupedRecords: GroupedRecords[] = []
  @State showAddDialog: boolean = false
  @State isLoading: boolean = true

  @State summaryMode: 'day' | 'month' | 'year' = 'month'
  @State summaryDate: Date = new Date()
  @State summaryIncome: number = 0
  @State summaryExpense: number = 0
  @State summaryNet: number = 0

  @State recordType: 'income' | 'expense' = 'expense'
  @State amount: string = ''
  @State selectedCategory: string = 'food'
  @State selectedDate: Date = new Date()
  @State note: string = ''

  private recordStore = RecordStore.getInstance()

  async aboutToAppear() {
    await this.loadData()
  }

  async loadData() {
    this.isLoading = true
    try {
      this.totalBalance = await this.recordStore.calculateBalance()
      const records = await this.recordStore.getAllRecords()
      this.allRecords = records
      this.groupedRecords = this.groupByDate(records)
      this.updateSummary(records)
    } catch (e) {
      console.error('加载数据失败:', e)
    }
    this.isLoading = false
  }

  groupByDate(records: Record[]): GroupedRecords[] {
    const map = new Map<string, Record[]>()
    for (const record of records) {
      const date = record.date
      if (!map.has(date)) {
        map.set(date, [])
      }
      map.get(date)!.push(record)
    }

    const result: GroupedRecords[] = []
    const sortedDates = Array.from(map.keys()).sort((a, b) => b.localeCompare(a))
    for (const date of sortedDates) {
      const dateRecords = map.get(date)!
      dateRecords.sort((a, b) => b.createTime - a.createTime)
      result.push(new GroupedRecords(date, this.formatDateDisplay(date), dateRecords))
    }
    return result
  }

  updateSummary(records: Record[]) {
    let income = 0
    let expense = 0
    for (const record of records) {
      if (!this.isRecordInCurrentPeriod(record.date)) {
        continue
      }
      if (record.type === 'income') {
        income += record.amount
      } else {
        expense += record.amount
      }
    }
    const summary = new SummaryData(income, expense)
    this.summaryIncome = summary.income
    this.summaryExpense = summary.expense
    this.summaryNet = summary.net
  }

  isRecordInCurrentPeriod(recordDate: string): boolean {
    const current = this.summaryDate
    if (this.summaryMode === 'day') {
      return recordDate === this.formatDate(current)
    }
    if (this.summaryMode === 'month') {
      const monthPrefix = `${current.getFullYear()}-${(current.getMonth() + 1).toString().padStart(2, '0')}`
      return recordDate.startsWith(monthPrefix)
    }
    return recordDate.startsWith(`${current.getFullYear()}-`)
  }

  changeSummaryMode(mode: 'day' | 'month' | 'year') {
    this.summaryMode = mode
    this.updateSummary(this.allRecords)
  }

  shiftSummaryDate(step: number) {
    const temp = new Date(this.summaryDate)
    if (this.summaryMode === 'day') {
      temp.setDate(temp.getDate() + step)
    } else if (this.summaryMode === 'month') {
      temp.setMonth(temp.getMonth() + step)
    } else {
      temp.setFullYear(temp.getFullYear() + step)
    }
    this.summaryDate = temp
    this.updateSummary(this.allRecords)
  }

  getSummaryPeriodText(): string {
    if (this.summaryMode === 'day') {
      return this.formatDate(this.summaryDate)
    }
    if (this.summaryMode === 'month') {
      return `${this.summaryDate.getFullYear()}-${(this.summaryDate.getMonth() + 1).toString().padStart(2, '0')}`
    }
    return `${this.summaryDate.getFullYear()}年`
  }

  formatDateDisplay(dateStr: string): string {
    const today = new Date()
    const yesterday = new Date(today)
    yesterday.setDate(yesterday.getDate() - 1)

    const todayStr = this.formatDate(today)
    const yesterdayStr = this.formatDate(yesterday)

    if (dateStr === todayStr) {
      return '今天'
    }
    if (dateStr === yesterdayStr) {
      return '昨天'
    }
    const date = new Date(dateStr)
    return `${date.getMonth() + 1}月${date.getDate()}日`
  }

  formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  getCategories() {
    return this.recordType === 'expense' ? ExpenseCategories : IncomeCategories
  }

  async addRecord() {
    const amountNum = parseFloat(this.amount)
    if (isNaN(amountNum) || amountNum <= 0) {
      return
    }

    const category = getCategoryById(this.recordType, this.selectedCategory)
    const dateStr = this.formatDate(this.selectedDate)

    const record = new Record(
      this.recordType,
      amountNum,
      this.selectedCategory,
      category.name,
      dateStr,
      this.note
    )

    await this.recordStore.addRecord(record)
    this.amount = ''
    this.note = ''
    this.selectedCategory = this.recordType === 'expense' ? 'food' : 'salary'
    this.selectedDate = new Date()
    this.showAddDialog = false
    await this.loadData()
  }

  async deleteRecord(id: string) {
    await this.recordStore.deleteRecord(id)
    await this.loadData()
  }

  build() {
    Stack() {
      Column() {
        if (this.activeTab === 'home') {
          this.HomeTab()
        } else {
          this.RecordTab()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      if (this.activeTab === 'record') {
        Button() {
          Text('+')
            .fontSize(32)
            .fontColor('#FFFFFF')
        }
        .width(60)
        .height(60)
        .backgroundColor('#36D1DC')
        .borderRadius(30)
        .position({ right: 20, bottom: 90 })
        .shadow({ radius: 8, color: '#40000000', offsetX: 2, offsetY: 2 })
        .onClick(() => {
          this.showAddDialog = true
        })
      }

      if (this.showAddDialog) {
        this.AddRecordDialog()
      }

      this.BottomNavBar()
    }
  }

  @Builder
  HomeTab() {
    Scroll() {
      Column() {
        Text('留点吧')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 30, bottom: 16 })

        Column() {
          Text('当前总资产 (元)')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .opacity(0.8)
          Text(this.totalBalance.toFixed(2))
            .fontSize(36)
            .fontWeight(FontWeight.Bolder)
            .fontColor('#FFFFFF')
            .margin({ top: 8 })
        }
        .width('90%')
        .height(140)
        .backgroundColor('#36D1DC')
        .borderRadius(20)
        .justifyContent(FlexAlign.Center)

        Column() {
          Text('收支汇总')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .alignSelf(ItemAlign.Start)

          Row() {
            Text('日')
              .fontSize(14)
              .fontColor(this.summaryMode === 'day' ? '#FFFFFF' : '#666666')
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .backgroundColor(this.summaryMode === 'day' ? '#36D1DC' : '#F0F0F0')
              .borderRadius(18)
              .onClick(() => {
                this.changeSummaryMode('day')
              })

            Text('月')
              .fontSize(14)
              .fontColor(this.summaryMode === 'month' ? '#FFFFFF' : '#666666')
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .backgroundColor(this.summaryMode === 'month' ? '#36D1DC' : '#F0F0F0')
              .borderRadius(18)
              .margin({ left: 10 })
              .onClick(() => {
                this.changeSummaryMode('month')
              })

            Text('年')
              .fontSize(14)
              .fontColor(this.summaryMode === 'year' ? '#FFFFFF' : '#666666')
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .backgroundColor(this.summaryMode === 'year' ? '#36D1DC' : '#F0F0F0')
              .borderRadius(18)
              .margin({ left: 10 })
              .onClick(() => {
                this.changeSummaryMode('year')
              })
          }
          .margin({ top: 12 })
          .alignSelf(ItemAlign.Start)

          Row() {
            Text('<')
              .fontSize(18)
              .fontColor('#666666')
              .onClick(() => {
                this.shiftSummaryDate(-1)
              })

            Text(this.getSummaryPeriodText())
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .margin({ left: 14, right: 14 })

            Text('>')
              .fontSize(18)
              .fontColor('#666666')
              .onClick(() => {
                this.shiftSummaryDate(1)
              })
          }
          .margin({ top: 16 })

          Column() {
            Row() {
              Text('收入')
                .fontSize(14)
                .fontColor('#666666')
              Blank()
              Text(`+${this.summaryIncome.toFixed(2)}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#52C41A')
            }

            Row() {
              Text('支出')
                .fontSize(14)
                .fontColor('#666666')
              Blank()
              Text(`-${this.summaryExpense.toFixed(2)}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FF4D4F')
            }
            .margin({ top: 10 })

            Row() {
              Text('净收益')
                .fontSize(14)
                .fontColor('#666666')
              Blank()
              Text(`${this.summaryNet >= 0 ? '+' : ''}${this.summaryNet.toFixed(2)}`)
                .fontSize(20)
                .fontWeight(FontWeight.Bolder)
                .fontColor(this.summaryNet >= 0 ? '#52C41A' : '#FF4D4F')
            }
            .margin({ top: 10 })
          }
          .width('100%')
          .margin({ top: 18 })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .margin({ top: 16, bottom: 90 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  RecordTab() {
    Column() {
      Text('记账')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30, bottom: 16 })

      Column() {
        Text('当前总资产 (元)')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .opacity(0.8)
        Text(this.totalBalance.toFixed(2))
          .fontSize(36)
          .fontWeight(FontWeight.Bolder)
          .fontColor('#FFFFFF')
          .margin({ top: 8 })
      }
      .width('90%')
      .height(140)
      .backgroundColor('#36D1DC')
      .borderRadius(20)
      .justifyContent(FlexAlign.Center)

      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontColor('#999999')
        }
        .margin({ top: 50 })
      } else if (this.groupedRecords.length === 0) {
        Column() {
          Text('还没有记账记录哦，去记一笔吧~')
            .fontColor('#999999')
        }
        .margin({ top: 50 })
      } else {
        Scroll() {
          Column() {
            ForEach(this.groupedRecords, (group: GroupedRecords) => {
              Text(group.dateDisplay)
                .fontSize(14)
                .fontColor('#666666')
                .margin({ top: 20, bottom: 10, left: 20 })
                .alignSelf(ItemAlign.Start)

              ForEach(group.records, (record: Record) => {
                this.RecordItem(record)
              })
            })
          }
          .margin({ bottom: 90 })
        }
        .width('100%')
        .margin({ top: 10 })
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  BottomNavBar() {
    Row() {
      Column() {
        HomeIcon({ isSelected: this.activeTab === 'home' })
        Text('主页')
          .fontSize(12)
          .fontColor(this.activeTab === 'home' ? '#36D1DC' : '#999999')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .padding({ top: 8, bottom: 10 })
      .onClick(() => {
        this.activeTab = 'home'
      })

      Column() {
        RecordIcon({ isSelected: this.activeTab === 'record' })
        Text('记账')
          .fontSize(12)
          .fontColor(this.activeTab === 'record' ? '#36D1DC' : '#999999')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .padding({ top: 8, bottom: 10 })
      .onClick(() => {
        this.activeTab = 'record'
      })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 1 }, color: '#EEEEEE' })
    .position({ bottom: 0 })
  }

  @Builder
  RecordItem(record: Record) {
    Row() {
      Text(getCategoryById(record.type, record.category).icon)
        .fontSize(24)
        .margin({ right: 12 })

      Column() {
        Text(record.categoryName)
          .fontSize(16)
          .fontColor('#333333')
        if (record.note) {
          Text(record.note)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(`${record.type === 'income' ? '+' : '-'}${record.amount.toFixed(2)}`)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(record.type === 'income' ? '#52C41A' : '#FF4D4F')

      Button('删除')
        .fontSize(12)
        .backgroundColor('#FFF1F0')
        .fontColor('#FF4D4F')
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .margin({ left: 10 })
        .onClick(() => {
          this.deleteRecord(record.id)
        })
    }
    .width('90%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 8 })
  }

  @Builder
  AddRecordDialog() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('#80000000')
      .onClick(() => {
        this.showAddDialog = false
      })

    Column() {
      Text('记账')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      Row() {
        Text('类型')
          .fontSize(16)
          .fontColor('#333333')

        Blank()

        Row() {
          Text('支出')
            .fontSize(14)
            .fontColor(this.recordType === 'expense' ? '#FFFFFF' : '#666666')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor(this.recordType === 'expense' ? '#FF4D4F' : '#F0F0F0')
            .borderRadius(20)
            .onClick(() => {
              this.recordType = 'expense'
              this.selectedCategory = 'food'
            })

          Text('收入')
            .fontSize(14)
            .fontColor(this.recordType === 'income' ? '#FFFFFF' : '#666666')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor(this.recordType === 'income' ? '#52C41A' : '#F0F0F0')
            .borderRadius(20)
            .margin({ left: 10 })
            .onClick(() => {
              this.recordType = 'income'
              this.selectedCategory = 'salary'
            })
        }
      }
      .width('100%')
      .margin({ bottom: 20 })

      Row() {
        Text('金额')
          .fontSize(16)
          .fontColor('#333333')

        Blank()

        TextInput({ text: this.amount, placeholder: '0.00' })
          .width(150)
          .type(InputType.NUMBER_DECIMAL)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding(10)
          .onChange((value) => {
            this.amount = value
          })

        Text(' 元')
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ bottom: 20 })

      Column() {
        Text('分类')
          .fontSize(16)
          .fontColor('#333333')
          .margin({ bottom: 10 })
          .alignSelf(ItemAlign.Start)

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.getCategories(), (cat: CategoryItem) => {
            Text(`${cat.icon} ${cat.name}`)
              .fontSize(14)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor(this.selectedCategory === cat.id ? '#36D1DC' : '#F0F0F0')
              .fontColor(this.selectedCategory === cat.id ? '#FFFFFF' : '#333333')
              .borderRadius(20)
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.selectedCategory = cat.id
              })
          })
        }
      }
      .width('100%')
      .margin({ bottom: 20 })

      Row() {
        Text('备注')
          .fontSize(16)
          .fontColor('#333333')

        Blank()

        TextInput({ text: this.note, placeholder: '可选' })
          .width(150)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding(10)
          .onChange((value) => {
            this.note = value
          })
      }
      .width('100%')
      .margin({ bottom: 30 })

      Row() {
        Button('取消')
          .layoutWeight(1)
          .backgroundColor('#F0F0F0')
          .fontColor('#666666')
          .onClick(() => {
            this.showAddDialog = false
          })

        Button('保存')
          .layoutWeight(1)
          .margin({ left: 15 })
          .backgroundColor('#36D1DC')
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.addRecord()
          })
      }
    }
    .width('90%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .position({ bottom: 0 })
  }
}
//xixi
