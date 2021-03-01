---
title: Go语言学习笔记
date: 2020-07-01 16:22:11
categories: Go
tags:
  - 学习笔记
---

# Go语言学习笔记

### 一、 运行时

#### 1.1 select 关键字

- **直接阻塞**：空 select 语句；空的 select 语句会直接阻塞当前的 Goroutine，导致 Goroutine 进入无法被唤醒的永久休眠状态。
- **单一管道**：select 条件只包含一个 case；如果当前的 select 条件只包含一个 case，当 case 中的 Channel 是空指针时，就会直接挂起当前 Goroutine 并永久休眠。
- **非阻塞操作**：当 select 中仅包含两个 case，并且其中一个是 default 时，Go 语言的编译器就会认为这是一次非阻塞的收发操作。如果 select 控制结构中包含 default 语句，那么这个 select 语句在执行时会遇到以下两种情况：

      1.当存在可以收发的 Channel 时，直接处理该 Channel 对应的 case；
      2.当不存在可以收发的 Channel 是，执行 default 中的语句；

    当我们运行下面的代码时就不会阻塞当前的 Goroutine，它会直接执行 default 中的代码并返回。

#### 1.2 

#### 1.4 同步原语与锁

本节会介绍 Go 语言中常见的同步原语 sync.Mutex、sync.RWMutex、sync.WaitGroup、sync.Once 和 sync.Cond 以及扩展原语 golang/sync/errgroup.Group、golang/sync/semaphore.Weighted 和 golang/sync/singleflight.Group 的实现原理，同时也会涉及互斥锁、信号量等并发编程中的常见概念。