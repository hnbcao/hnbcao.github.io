# 同步原语与锁

​    本节会介绍 Go 语言中常见的同步原语 sync.Mutex、sync.RWMutex、sync.WaitGroup、sync.Once 和 sync.Cond 以及扩展原语 golang/sync/errgroup.Group、golang/sync/semaphore.Weighted 和 golang/sync/singleflight.Group 的实现原理，同时也会涉及互斥锁、信号量等并发编程中的常见概念。