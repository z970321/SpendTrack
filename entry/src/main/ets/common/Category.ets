export class CategoryItem {
  id: string
  name: string
  icon: string

  constructor(id: string, name: string, icon: string) {
    this.id = id
    this.name = name
    this.icon = icon
  }
}

export const ExpenseCategories: CategoryItem[] = [
  new CategoryItem('food', '餐饮', '🍜'),
  new CategoryItem('transport', '交通', '🚗'),
  new CategoryItem('shopping', '购物', '🛍️'),
  new CategoryItem('entertainment', '娱乐', '🎮'),
  new CategoryItem('housing', '住房', '🏠'),
  new CategoryItem('medical', '医疗', '💊'),
  new CategoryItem('education', '教育', '📚'),
  new CategoryItem('other', '其他', '📦')
]

export const IncomeCategories: CategoryItem[] = [
  new CategoryItem('salary', '工资', '💰'),
  new CategoryItem('bonus', '奖金', '🎁'),
  new CategoryItem('investment', '投资', '📈'),
  new CategoryItem('gift', '礼金', '🧧'),
  new CategoryItem('other', '其他', '💵')
]

export function getCategoryById(type: 'income' | 'expense', id: string): CategoryItem {
  const categories = type === 'expense' ? ExpenseCategories : IncomeCategories
  const found = categories.find((item: CategoryItem) => item.id === id)
  if (found) {
    return found
  }
  return new CategoryItem('other', '其他', '📦')
}
