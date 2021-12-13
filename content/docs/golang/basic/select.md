---
title: Select 关键字
weight: 1
---

# Select 关键字

## 一、实现原理

- **直接阻塞**：空 select 语句；空的 select 语句会直接阻塞当前的 Goroutine，导致 Goroutine 进入无法被唤醒的永久休眠状态。
- **单一管道**：select 条件只包含一个 case；如果当前的 select 条件只包含一个 case，当 case 中的 Channel 是空指针时，就会直接挂起当前 Goroutine 并永久休眠。
- **非阻塞操作**：当 select 中仅包含两个 case，并且其中一个是 default 时，Go 语言的编译器就会认为这是一次非阻塞的收发操作。如果 select 控制结构中包含 default 语句，那么这个 select 语句在执行时会遇到以下两种情况：

  1.当存在可以收发的 Channel 时，直接处理该 Channel 对应的 case；

  2.当不存在可以收发的 Channel 是，执行 default 中的语句；

  当我们运行下面的代码时就不会阻塞当前的 Goroutine，它会直接执行 default 中的代码并返回。

  ```go
  func main() {
    ch := make(chan int)
    select {
    case i := <-ch:
      println(i)

    default:
      println("default")
    }
  }
  ```

## 二、小结

我们简单总结一下 select 结构的执行过程与实现原理，首先在编译期间，Go 语言会对 select 语句进行优化，它会根据 select 中 case 的不同选择不同的优化路径：

1. 空的 select 语句会被转换成调用 runtime.block 直接挂起当前 Goroutine；

2. 如果 select 语句中只包含一个 case，编译器会将其转换成 if ch == nil { block }; n; 表达式；
首先判断操作的 Channel 是不是空的；
然后执行 case 结构中的内容；

3. 如果 select 语句中只包含两个 case 并且其中一个是 default，那么会使用 runtime.selectnbrecv 和 runtime.selectnbsend 非阻塞地执行收发操作；

4. 在默认情况下会通过 runtime.selectgo 获取执行 case 的索引，并通过多个 if 语句执行对应 case 中的代码；

在编译器已经对 select 语句进行优化之后，Go 语言会在运行时执行编译期间展开的 runtime.selectgo 函数，该函数会按照以下的流程执行：

1. 随机生成一个遍历的轮询顺序 pollOrder 并根据 Channel 地址生成锁定顺序 lockOrder；

2. 根据 pollOrder 遍历所有的 case 查看是否有可以立刻处理的 Channel；

  1. 如果存在，直接获取 case 对应的索引并返回；

  2. 如果不存在，创建 runtime.sudog 结构体，将当前 Goroutine 加入到所有相关 Channel 的收发队列，并调用 runtime.gopark 挂起当前 Goroutine 等待调度器的唤醒；

3. 当调度器唤醒当前 Goroutine 时，会再次按照 lockOrder 遍历所有的 case，从中查找需要被处理的 runtime.sudog 对应的索引；

select 关键字是 Go 语言特有的控制结构，它的实现原理比较复杂，需要编译器和运行时函数的通力合作。