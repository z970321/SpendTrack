import { Record } from '../common/Record'
import { DayCellData, DayRowData, MetricBlockData } from '../models/ViewData'

@Component
export struct HomeView {
  @Link allRecords: Record[]
  @State summaryMode: 'day' | 'week' | 'month' | 'year' = 'month'
  @State summaryDate: Date = new Date()
  @State selectedDay: number = new Date().getDate()

  getWeekStart(date: Date): Date {
    const start = new Date(date)
    const weekDay = start.getDay()
    const offset = weekDay === 0 ? 6 : weekDay - 1
    start.setDate(start.getDate() - offset)
    start.setHours(0, 0, 0, 0)
    return start
  }

  changeSummaryMode(mode: 'day' | 'week' | 'month' | 'year') {
    this.summaryMode = mode
  }

  shiftSummaryDate(step: number) {
    const temp = new Date(this.summaryDate)
    if (this.summaryMode === 'day' || this.summaryMode === 'week') {
      temp.setMonth(temp.getMonth() + step)
      const daysInMonth = new Date(temp.getFullYear(), temp.getMonth() + 1, 0).getDate()
      this.selectedDay = Math.min(this.selectedDay, daysInMonth)
      temp.setDate(this.selectedDay)
    } else {
      temp.setFullYear(temp.getFullYear() + step)
    }
    this.summaryDate = temp
  }

  getDailyNetByDate(dateStr: string): number {
    let income = 0
    let expense = 0
    for (const record of this.allRecords) {
      if (record.date !== dateStr) {
        continue
      }
      if (record.type === 'income') {
        income += record.amount
      } else {
        expense += record.amount
      }
    }
    return income - expense
  }

  getNetBetween(start: Date, end: Date): number {
    let income = 0
    let expense = 0
    for (const record of this.allRecords) {
      const d = new Date(record.date)
      if (d < start || d > end) {
        continue
      }
      if (record.type === 'income') {
        income += record.amount
      } else {
        expense += record.amount
      }
    }
    return income - expense
  }

  getMonthNet(year: number, month: number): number {
    const start = new Date(year, month - 1, 1)
    const end = new Date(year, month, 0)
    return this.getNetBetween(start, end)
  }

  getYearNet(year: number): number {
    const start = new Date(year, 0, 1)
    const end = new Date(year, 11, 31)
    return this.getNetBetween(start, end)
  }

  netColor(net: number): string {
    if (net > 0) {
      return '#52C41A'
    }
    if (net < 0) {
      return '#FF4D4F'
    }
    return '#9E9E9E'
  }

  formatNetText(net: number): string {
    if (net > 0) {
      return `+${net.toFixed(2)}`
    }
    return net.toFixed(2)
  }

  getDayRows(): DayRowData[] {
    const year = this.summaryDate.getFullYear()
    const month = this.summaryDate.getMonth()
    const firstWeekday = new Date(year, month, 1).getDay()
    const daysInMonth = new Date(year, month + 1, 0).getDate()

    const cells: DayCellData[] = []
    for (let i = 0; i < firstWeekday; i++) {
      cells.push(new DayCellData(`blank-${i}`, 0, '', '', '#9E9E9E', false, false))
    }

    for (let day = 1; day <= daysInMonth; day++) {
      const dateText = `${year}-${(month + 1).toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`
      const net = this.getDailyNetByDate(dateText)
      const valueText = net === 0 ? '' : this.formatNetText(net)
      cells.push(new DayCellData(`day-${day}`, day, `${day}`, valueText, this.netColor(net), true, this.selectedDay === day))
    }

    const rest = cells.length % 7
    if (rest !== 0) {
      for (let i = 0; i < 7 - rest; i++) {
        cells.push(new DayCellData(`tail-${i}`, 0, '', '', '#9E9E9E', false, false))
      }
    }

    const rows: DayRowData[] = []
    const rowCount = cells.length / 7
    for (let r = 0; r < rowCount; r++) {
      rows.push(new DayRowData(`row-${r}`, cells.slice(r * 7, r * 7 + 7)))
    }
    return rows
  }

  getWeekBlocks(): MetricBlockData[] {
    const year = this.summaryDate.getFullYear()
    const month = this.summaryDate.getMonth()
    const firstDay = new Date(year, month, 1)
    const lastDay = new Date(year, month + 1, 0)
    let start = this.getWeekStart(firstDay)
    const selectedStart = this.getWeekStart(this.summaryDate)
    const selectedKey = `${selectedStart.getFullYear()}-${(selectedStart.getMonth() + 1).toString().padStart(2, '0')}-${selectedStart.getDate().toString().padStart(2, '0')}`
    const blocks: MetricBlockData[] = []

    while (start <= lastDay) {
      const end = new Date(start)
      end.setDate(start.getDate() + 6)
      const key = `${start.getFullYear()}-${(start.getMonth() + 1).toString().padStart(2, '0')}-${start.getDate().toString().padStart(2, '0')}`
      const title = `${start.getMonth() + 1}.${start.getDate()}-${end.getMonth() + 1}.${end.getDate()}`
      const net = this.getNetBetween(start, end)
      blocks.push(new MetricBlockData(key, title, net === 0 ? '' : this.formatNetText(net), this.netColor(net), key === selectedKey, false))
      start = new Date(start)
      start.setDate(start.getDate() + 7)
    }
    return blocks
  }

  getMonthBlocks(): MetricBlockData[] {
    const year = this.summaryDate.getFullYear()
    const blocks: MetricBlockData[] = []
    for (let m = 1; m <= 12; m++) {
      const net = this.getMonthNet(year, m)
      blocks.push(new MetricBlockData(`month-${m}`, `${m}月`, net === 0 ? '' : this.formatNetText(net), this.netColor(net), m === this.summaryDate.getMonth() + 1, false))
    }
    return blocks
  }

  getYearBlocks(): MetricBlockData[] {
    const currentYear = new Date().getFullYear()
    let minYear = currentYear
    for (const record of this.allRecords) {
      const y = new Date(record.date).getFullYear()
      if (y < minYear) {
        minYear = y
      }
    }

    const count = Math.min(6, currentYear - minYear + 1)
    const blocks: MetricBlockData[] = []
    for (let i = 0; i < count; i++) {
      const year = currentYear - i
      const net = this.getYearNet(year)
      blocks.push(new MetricBlockData(`year-${year}`, `${year}`, net === 0 ? '' : this.formatNetText(net), this.netColor(net), year === this.summaryDate.getFullYear(), false))
    }
    for (let i = count; i < 6; i++) {
      blocks.push(new MetricBlockData(`placeholder-${i}`, '', '', '#9E9E9E', false, true))
    }
    return blocks
  }

  selectDayCell(cell: DayCellData) {
    if (!cell.inCurrentMonth) {
      return
    }
    this.selectedDay = cell.dayNumber
    this.summaryDate = new Date(this.summaryDate.getFullYear(), this.summaryDate.getMonth(), cell.dayNumber)
  }

  selectWeekBlock(block: MetricBlockData) {
    if (block.isPlaceholder) {
      return
    }
    const parts = block.key.split('-')
    if (parts.length !== 3) {
      return
    }
    this.summaryDate = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]))
  }

  selectMonthBlock(block: MetricBlockData) {
    if (block.isPlaceholder) {
      return
    }
    const month = Number(block.key.replace('month-', ''))
    if (month <= 0) {
      return
    }
    this.summaryDate = new Date(this.summaryDate.getFullYear(), month - 1, 1)
  }

  selectYearBlock(block: MetricBlockData) {
    if (block.isPlaceholder) {
      return
    }
    const year = Number(block.key.replace('year-', ''))
    if (year <= 0) {
      return
    }
    this.summaryDate = new Date(year, 0, 1)
  }

  @Builder
  DayCell(cell: DayCellData) {
    Column() {
      Text(cell.dayText)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(cell.isSelected ? '#FFFFFF' : (cell.inCurrentMonth ? '#2D2D2D' : '#D0D0D0'))

      Text(cell.valueText)
        .fontSize(14)
        .fontColor(cell.valueColor)
        .margin({ top: 8 })
    }
    .layoutWeight(1)
    .height(78)
    .justifyContent(FlexAlign.Center)
    .borderRadius(16)
    .backgroundColor(cell.isSelected ? '#A5A6AA' : (cell.inCurrentMonth ? '#F3F3F4' : 'transparent'))
    .shadow(cell.isSelected ? { radius: 8, color: '#22000000', offsetX: 0, offsetY: 2 } : { radius: 0, color: '#00000000', offsetX: 0, offsetY: 0 })
    .margin({ left: 2, right: 2 })
    .onClick(() => {
      this.selectDayCell(cell)
    })
  }

  @Builder
  MetricBlock(block: MetricBlockData, onTap: () => void) {
    Column() {
      Text(block.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(block.isPlaceholder ? '#D0D0D0' : (block.isSelected ? '#FFFFFF' : '#333333'))

      Text(block.valueText)
        .fontSize(14)
        .fontColor(block.valueColor)
        .margin({ top: 8 })
    }
    .width('31%')
    .height(74)
    .justifyContent(FlexAlign.Center)
    .borderRadius(14)
    .backgroundColor(block.isPlaceholder ? 'transparent' : (block.isSelected ? '#A5A6AA' : '#F3F3F4'))
    .margin({ left: '1%', right: '1%', bottom: 8 })
    .onClick(() => {
      onTap()
    })
  }

  build() {
    Scroll() {
      Column() {
        Column() {
          Row() {
            Text('日')
              .fontSize(16)
              .fontWeight(this.summaryMode === 'day' ? FontWeight.Medium : FontWeight.Regular)
              .fontColor(this.summaryMode === 'day' ? '#007DFF' : '#666666')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.changeSummaryMode('day')
              })
            Text('月')
              .fontSize(16)
              .fontWeight(this.summaryMode === 'month' ? FontWeight.Medium : FontWeight.Regular)
              .fontColor(this.summaryMode === 'month' ? '#007DFF' : '#666666')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.changeSummaryMode('month')
              })
            Text('年')
              .fontSize(16)
              .fontWeight(this.summaryMode === 'year' ? FontWeight.Medium : FontWeight.Regular)
              .fontColor(this.summaryMode === 'year' ? '#007DFF' : '#666666')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.changeSummaryMode('year')
              })
          }
          .width('100%')

          Row() {
            Row() {
              Text('‹')
                .fontSize(34)
                .fontColor('#BBBBBB')
            }
            .width('24%')
            .height(56)
            .backgroundColor('#FAFAFA')
            .borderRadius(18)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.shiftSummaryDate(-1)
            })

            Row() {
              Text(this.summaryMode === 'year' ? `${this.summaryDate.getFullYear()}年` : `${this.summaryDate.getFullYear()}年 ${(this.summaryDate.getMonth() + 1)}月`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2F2F2F')
            }
            .layoutWeight(1)
            .height(56)
            .backgroundColor('#FAFAFA')
            .borderRadius(18)
            .justifyContent(FlexAlign.Center)
            .margin({ left: 10, right: 10 })

            Row() {
              Text('›')
                .fontSize(34)
                .fontColor('#E0E0E0')
            }
            .width('24%')
            .height(56)
            .backgroundColor('#FAFAFA')
            .borderRadius(18)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.shiftSummaryDate(1)
            })
          }
          .width('100%')
          .margin({ top: 16, bottom: 14 })

          if (this.summaryMode === 'day') {
            Row() {
              Text('日').fontSize(16).fontColor('#303030').layoutWeight(1).textAlign(TextAlign.Center)
              Text('一').fontSize(16).fontColor('#303030').layoutWeight(1).textAlign(TextAlign.Center)
              Text('二').fontSize(16).fontColor('#303030').layoutWeight(1).textAlign(TextAlign.Center)
              Text('三').fontSize(16).fontColor('#303030').layoutWeight(1).textAlign(TextAlign.Center)
              Text('四').fontSize(16).fontColor('#303030').layoutWeight(1).textAlign(TextAlign.Center)
              Text('五').fontSize(16).fontColor('#303030').layoutWeight(1).textAlign(TextAlign.Center)
              Text('六').fontSize(16).fontColor('#303030').layoutWeight(1).textAlign(TextAlign.Center)
            }
            .width('100%')
            .margin({ bottom: 10 })

            ForEach(this.getDayRows(), (row: DayRowData) => {
              Row() {
                ForEach(row.cells, (cell: DayCellData) => {
                  this.DayCell(cell)
                })
              }
              .width('100%')
              .margin({ bottom: 6 })
            })
          } else if (this.summaryMode === 'week') {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.getWeekBlocks(), (block: MetricBlockData) => {
                this.MetricBlock(block, () => {
                  this.selectWeekBlock(block)
                })
              })
            }
            .width('100%')
          } else if (this.summaryMode === 'month') {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.getMonthBlocks(), (block: MetricBlockData) => {
                this.MetricBlock(block, () => {
                  this.selectMonthBlock(block)
                })
              })
            }
            .width('100%')
          } else {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.getYearBlocks(), (block: MetricBlockData) => {
                this.MetricBlock(block, () => {
                  this.selectYearBlock(block)
                })
              })
            }
            .width('100%')
          }
        }
        .width('94%')
        .padding(14)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .shadow({ radius: 10, color: '#12000000', offsetX: 0, offsetY: 2 })
        .margin({ top: 24, bottom: 100 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}
