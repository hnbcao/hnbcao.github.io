---
title: 1. 语言基础
weight: 1
---

# 语言基础

## 1.1. 数组和切片

### 1.1.1 数组

对于一个由字面量组成的数组，根据数组元素数量的不同，编译器会在负责初始化字面量的 cmd/compile/internal/gc.anylit 函数中做两种不同的优化：

- 当元素数量小于或者等于 4 个时，会直接将数组中的元素放置在栈上；

- 当元素数量大于 4 个时，会将数组中的元素放置到静态区并在运行时取出；

### 1.1.2 切片

类型：

```go
type SliceHeader struct {
	Data uintptr
	Len  int
	Cap  int
}
```

**循环永动机**：对于所有的 range 循环，Go 语言都会在编译期将原切片或者数组赋值给一个新变量 ha，在赋值的过程中就发生了拷贝，而我们又通过 len 关键字预先获取了切片的长度，所以在循环中追加新的元素也不会改变循环执行的次数。

## 1.2. 哈希表

首先会选出一个绿色的正常桶开始遍历，随后遍历所有黄色的溢出桶，最后依次按照索引顺序遍历哈希表中其他的桶，直到所有的桶都被遍历完成。

## 1.3. 字符串

遍历字符串时拿到的值都是 `rune` 类型的变量，`for i, r := range s {}` 的结构都会被转换成如下所示的形式：

```go
ha := s
for hv1 := 0; hv1 < len(ha); {
    hv1t := hv1
    hv2 := rune(ha[hv1])
    if hv2 < utf8.RuneSelf {
        hv1++
    } else {
        hv2, hv1 = decoderune(ha, hv1)
    }
    v1, v2 = hv1t, hv2
}
```

## 1.4. 通道

使用 range 遍历 Channel 也是比较常见的做法，一个形如 `for v := range ch {}` 的语句最终会被转换成如下的格式：

```go
ha := a
hv1, hb := <-ha
for ; hb != false; hv1, hb = <-ha {
    v1 := hv1
    hv1 = nil
    ...
}
```

​	该循环会使用 `<-ch` 从管道中取出等待处理的值，这个操作会调用 [`runtime.chanrecv2`](https://draveness.me/golang/tree/runtime.chanrecv2) 并阻塞当前的协程，当 [`runtime.chanrecv2`](https://draveness.me/golang/tree/runtime.chanrecv2) 返回时会根据布尔值 `hb` 判断当前的值是否存在：

- 如果不存在当前值，意味着当前的管道已经被关闭；
- 如果存在当前值，会为 `v1` 赋值并清除 `hv1` 变量中的数据，然后重新陷入阻塞等待新数据；

