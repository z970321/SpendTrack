// 记账记录数据模型
export class Record {
  id: string
  type: 'income' | 'expense'  // 收入或支出
  amount: number               // 金额
  category: string            // 分类
  categoryName: string        // 分类名称
  date: string                 // 日期 (YYYY-MM-DD)
  note: string                // 备注
  createTime: number          // 创建时间戳

  constructor(type: 'income' | 'expense', amount: number, category: string, categoryName: string, date: string, note: string = '') {
    this.id = Date.now().toString() + Math.random().toString().slice(2, 8)
    this.type = type
    this.amount = amount
    this.category = category
    this.categoryName = categoryName
    this.date = date
    this.note = note
    this.createTime = Date.now()
  }
}
