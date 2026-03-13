import { Record } from '../common/Record'
import { GroupedRecords } from '../models/ViewData'
import { getCategoryById, CategoryItem, ExpenseCategories, IncomeCategories } from '../common/Category'

@Component
export struct RecordView {
  @Prop totalBalance: number
  @Prop isLoading: boolean
  @Link groupedRecords: GroupedRecords[]

  // 接收外部传入的删除方法
  public onDeleteRecord?: (id: string) => void

  build() {
    Column() {
      Text('账单明细')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })
        .width('90%')
        .textAlign(TextAlign.Start)

      // 美化：渐变色总资产卡片
      Column() {
        Text('当前总资产 (元)')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .opacity(0.9)
          .margin({ bottom: 8 })
        Text(this.totalBalance.toFixed(2))
          .fontSize(40)
          .fontWeight(FontWeight.Bolder)
          .fontColor('#FFFFFF')
      }
      .width('90%')
      .height(130)
      // 使用线性渐变替代单一颜色，提升质感
      .linearGradient({
        angle: 135,
        colors: [['#007DFF', 0.0], ['#36D1DC', 1.0]]
      })
      .borderRadius(24)
      .shadow({ radius: 15, color: '#30007DFF', offsetY: 8 })
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 20 })

      if (this.isLoading) {
        Column() { Text('数据加载中...').fontColor('#999999').margin({ top: 40 }) }
      } else if (this.groupedRecords.length === 0) {
        Column() { Text('还没有记账记录哦，去记一笔吧~').fontColor('#999999').margin({ top: 40 }) }
      } else {
        Scroll() {
          Column() {
            ForEach(this.groupedRecords, (group: GroupedRecords) => {
              Text(group.dateDisplay)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#888888')
                .margin({ top: 20, bottom: 10, left: 24 })
                .alignSelf(ItemAlign.Start)

              ForEach(group.records, (record: Record) => {
                this.RecordItemCard(record)
              })
            })
          }
          .margin({ bottom: 90 })
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  RecordItemCard(record: Record) {
    Row() {
      // 图标外加一个浅色背景圈
      Row() {
        Text(getCategoryById(record.type, record.category).icon).fontSize(20)
      }
      .width(40).height(40)
      .backgroundColor('#F5F7FA')
      .borderRadius(20)
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      Column() {
        Text(record.categoryName).fontSize(16).fontWeight(FontWeight.Medium).fontColor('#333333')
        if (record.note) {
          Text(record.note).fontSize(12).fontColor('#999999').margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(`${record.type === 'income' ? '+' : '-'}${record.amount.toFixed(2)}`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(record.type === 'income' ? '#52C41A' : '#333333') // 支出改为深黑更现代，收入保持绿色

      Button('删除')
        .fontSize(12)
        .backgroundColor('transparent')
        .fontColor('#FF4D4F')
        .margin({ left: 10 })
        .onClick(() => {
          if (this.onDeleteRecord) {
            this.onDeleteRecord(record.id)
          }
        })
    }
    .width('90%')
    .padding({ left: 16, right: 16, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ bottom: 12 })
    .shadow({ radius: 8, color: '#05000000', offsetY: 2 }) // 微小的悬浮感
  }
}