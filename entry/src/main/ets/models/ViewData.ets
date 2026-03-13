import { Record } from '../common/Record'

export class GroupedRecords {
  date: string
  dateDisplay: string
  records: Record[]

  constructor(date: string, dateDisplay: string, records: Record[]) {
    this.date = date
    this.dateDisplay = dateDisplay
    this.records = records
  }
}

export class DayCellData {
  key: string
  dayNumber: number
  dayText: string
  valueText: string
  valueColor: string
  inCurrentMonth: boolean
  isSelected: boolean

  constructor(key: string, dayNumber: number, dayText: string, valueText: string, valueColor: string, inCurrentMonth: boolean, isSelected: boolean) {
    this.key = key
    this.dayNumber = dayNumber
    this.dayText = dayText
    this.valueText = valueText
    this.valueColor = valueColor
    this.inCurrentMonth = inCurrentMonth
    this.isSelected = isSelected
  }
}

export class DayRowData {
  key: string
  cells: DayCellData[]

  constructor(key: string, cells: DayCellData[]) {
    this.key = key
    this.cells = cells
  }
}

export class MetricBlockData {
  key: string
  title: string
  valueText: string
  valueColor: string
  isSelected: boolean
  isPlaceholder: boolean

  constructor(key: string, title: string, valueText: string, valueColor: string, isSelected: boolean, isPlaceholder: boolean) {
    this.key = key
    this.title = title
    this.valueText = valueText
    this.valueColor = valueColor
    this.isSelected = isSelected
    this.isPlaceholder = isPlaceholder
  }
}