# 上下文 Context

### 方法实现

context.Context 是 Go 语言在 1.7 版本中引入标准库的接口1，该接口定义了四个需要实现的方法，其中包括：

1. Deadline — 返回 context.Context 被取消的时间，也就是完成工作的截止日期；

2. Done — 返回一个 Channel，这个 Channel 会在当前工作完成或者上下文被取消后关闭，多次调用 Done 方法会返回同一个 Channel；

3. Err — 返回 context.Context 结束的原因，它只会在 Done 方法对应的 Channel 关闭时返回非空的值；

    1. 如果 context.Context 被取消，会返回 Canceled 错误；
    
    2. 如果 context.Context 超时，会返回 DeadlineExceeded 错误；

4. Value — 从 context.Context 中获取键对应的值，对于同一个上下文来说，多次调用 Value 并传入相同的 Key 会返回相同的结果，该方法可以用来传递请求特定的数据；

### 默认上下文 

从源代码来看，context.Background 和 context.TODO 也只是互为别名，没有太大的差别，只是在使用和语义上稍有不同：

- context.Background 是上下文的默认值，所有其他的上下文都应该从它衍生出来；

- context.TODO 应该仅在不确定应该使用哪种上下文时使用；

在多数情况下，如果当前函数没有上下文作为入参，我们都会使用 context.Background 作为起始的上下文向下传递。

### 小结

Go 语言中的 context.Context 的主要作用还是在多个 Goroutine 组成的树中同步取消信号以减少对资源的消耗和占用，虽然它也有传值的功能，但是这个功能我们还是很少用到。

在真正使用传值的功能时我们也应该非常谨慎，使用 context.Context 进行传递参数请求的所有参数一种非常差的设计，比较常见的使用场景是传递请求对应用户的认证令牌以及用于进行分布式追踪的请求 ID。