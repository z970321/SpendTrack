@Component
export struct HomeIcon {
  @Prop isSelected: boolean = false

  build() {
    Column() {
      Polygon()
        .width(20)
        .height(10)
        .points([[10, 0], [0, 10], [20, 10]])
        .fill(this.isSelected ? '#007DFF' : '#B0B0B0') // 优化了选中和未选中的颜色

      Rect()
        .width(16)
        .height(10)
        .fill(this.isSelected ? '#007DFF' : '#B0B0B0')
        .margin({ top: -1 })
    }
    .justifyContent(FlexAlign.Center)
    .width(24)
    .height(24)
  }
}

@Component
export struct RecordIcon {
  @Prop isSelected: boolean = false

  build() {
    Stack() {
      Rect()
        .width(18)
        .height(22)
        .radius(4) // 增加了一点圆角，显得更柔和
        .fill(this.isSelected ? '#007DFF' : '#B0B0B0')

      Column() {
        Rect().width(10).height(1.5).fill('#FFFFFF').margin({ bottom: 2 })
        Rect().width(10).height(1.5).fill('#FFFFFF').margin({ bottom: 2 })
        Rect().width(10).height(1.5).fill('#FFFFFF')
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