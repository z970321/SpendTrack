import { Record } from '../common/Record'
import { RecordStore } from '../common/RecordStore'
import { CategoryItem, ExpenseCategories, IncomeCategories, getCategoryById } from '../common/Category'
import { GroupedRecords } from '../models/ViewData'
import { HomeIcon, RecordIcon } from '../components/CommonComponents'
import { HomeView } from '../views/HomeView'
import { RecordView } from '../views/RecordView'

@Entry
@Component
struct Index {
  @State activeTab: 'home' | 'record' = 'home'
  @State totalBalance: number = 0
  @State allRecords: Record[] = []
  @State groupedRecords: GroupedRecords[] = []
  @State showAddDialog: boolean = false
  @State isLoading: boolean = true

  @State homeScale: number = 1
  @State recordScale: number = 1

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
    } catch (e) {
      console.error('加载数据失败:', e)
    }
    this.isLoading = false
  }

  groupByDate(records: Record[]): GroupedRecords[] {
    const map = new Map<string, Record[]>()
    for (const record of records) {
      if (!map.has(record.date)) {
        map.set(record.date, [])
      }
      map.get(record.date)!.push(record)
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

  async handleDeleteRecord(id: string) {
    await this.recordStore.deleteRecord(id)
    await this.loadData()
  }

  build() {
    Stack() {
      Column() {
        if (this.activeTab === 'home') {
          HomeView({ allRecords: $allRecords })
        } else {
          RecordView({
            totalBalance: this.totalBalance,
            isLoading: this.isLoading,
            groupedRecords: $groupedRecords,
            onDeleteRecord: (id: string): void => {
              this.handleDeleteRecord(id)
            }
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      if (this.showAddDialog) {
        this.AddRecordDialog()
      }

      this.BottomNavBar()
    }
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
      .scale({ x: this.homeScale, y: this.homeScale })
      .animation({ duration: 140, curve: Curve.EaseOut })
      .padding({ top: 10, bottom: 8 })
      .onTouch((event) => {
        if (event.type === TouchType.Down) {
          this.homeScale = 0.95
        }
        if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.homeScale = 1
        }
      })
      .onClick(() => {
        this.activeTab = 'home'
        this.recordScale = 1
      })

      Column() {
        RecordIcon({ isSelected: this.activeTab === 'record' })
        Text(this.activeTab === 'record' ? '新增' : '记账')
          .fontSize(12)
          .fontColor(this.activeTab === 'record' ? '#36D1DC' : '#999999')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .scale({ x: this.recordScale, y: this.recordScale })
      .animation({ duration: 140, curve: Curve.EaseOut })
      .padding({ top: 10, bottom: 8 })
      .onTouch((event) => {
        if (event.type === TouchType.Down) {
          this.recordScale = 0.95
        }
        if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.recordScale = 1
        }
      })
      .onClick(() => {
        this.homeScale = 1
        if (this.activeTab === 'record') {
          this.showAddDialog = true
        } else {
          this.activeTab = 'record'
        }
      })
    }
    .width('100%')
    .height(70)
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 1 }, color: '#EEEEEE' })
    .position({ bottom: 0 })
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
    .position({ bottom: 78 })
  }
}
