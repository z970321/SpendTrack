@Entry
@Component
struct Index {
  @State totalBalance: string = '8888.88' // 总资产

  build() {
    Column() {
      // 顶部标题栏
      Text('碎银几两')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30, bottom: 20 })

      // 总资产卡片
      Column() {
        Text('当前剩余 (元)')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .opacity(0.8)
        Text(this.totalBalance)
          .fontSize(40)
          .fontWeight(FontWeight.Bolder)
          .fontColor('#FFFFFF')
          .margin({ top: 10 })
      }
      .width('90%')
      .height(150)
      .backgroundColor('#36D1DC') // 这是一个漂亮的蓝色
      .borderRadius(20)
      .justifyContent(FlexAlign.Center)
      .shadow({ radius: 10, color: '#20000000', offsetX: 5, offsetY: 5 })

      // 占位提示
      Text('还没有记账记录哦，去花一笔吧~')
        .margin({ top: 50 })
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}