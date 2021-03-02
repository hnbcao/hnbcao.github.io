# 逃逸分析

#### 什么是逃逸分析？

所谓逃逸分析（Escape analysis）是指由编译器决定内存分配的位置，不需要程序员指定。

在函数中申请一个新的对象：

- 如果分配 在栈中，则函数执行结束可自动将内存回收；
- 如果分配在堆中，则函数执行结束可交给GC（垃圾回收）处理;

> 注意，对于函数外部没有引用的对象，也有可能放到堆中，比如内存过大超过栈的存储能力。

#### 逃逸场景

- **指针逃逸**： Go可以返回局部变量指针，这其实是一个典型的变量逃逸案例，示例代码如下：

  ```go
  package main
  
  type Student struct {
      Name string
      Age  int
  }
  
  func StudentRegister(name string, age int) *Student {
      s := new(Student) //局部变量s逃逸到堆
  
      s.Name = name
      s.Age = age
  
      return s
  }
  
  func main() {
      StudentRegister("Jim", 18)
  }
  ```

  虽然 在函数 StudentRegister() 内部 s 为局部变量，其值通过函数返回值返回，s 本身为一指针，其指向的内存地址不会是栈而是堆，这就是典型的逃逸案例。

- **栈空间不足逃逸（空间开辟过大）**：

  ```go
  package main
  
  func Slice() {
      s := make([]int, 10000, 10000)
  
      for index, _ := range s {
          s[index] = index
      }
  }
  
  func main() {
      Slice()
  }
  ```

  当切片长度扩大到10000时就会逃逸。

  实际上当栈空间不足以存放当前对象时或无法判断当前切片长度时会将对象分配到堆中。

- **动态类型逃逸（不确定长度大小）**:很多函数参数为interface类型，比如fmt.Println(a …interface{})，编译期间很难确定其参数的具体类型，也能产生逃逸。

  如下代码所示：

  ```go
  package main
  
  import "fmt"
  
  func main() {
      s := "Escape"
      fmt.Println(s)
  }
  ```

- **闭包引用对象逃逸**: 

  ```go
  package main
  
  import "fmt"
  
  func Fibonacci() func() int {
      a, b := 0, 1
      return func() int {
          a, b = b, a+b
          return a
      }
  }
  
  func main() {
      f := Fibonacci()
  
      for i := 0; i < 10; i++ {
          fmt.Printf("Fibonacci: %d\n", f())
      }
  }
  ```

  Fibonacci()函数中原本属于局部变量的a和b由于闭包的引用，不得不将二者放到堆上，以致产生逃逸。

#### 逃逸分析的作用

1. 逃逸分析的好处是为了减少gc的压力，不逃逸的对象分配在栈上，当函数返回时就回收了资源，不需要gc标记清除。
2. 逃逸分析完后可以确定哪些变量可以分配在栈上，栈的分配比堆快，性能好(逃逸的局部变量会在堆上分配 ,而没有发生逃逸的则有编译器在栈上分配)。
3. 同步消除，如果你定义的对象的方法上有同步锁，但在运行时，却只有一个线程在访问，此时逃逸分析后的机器码，会去掉同步锁运行。

#### 逃逸总结

- 栈上分配内存比在堆中分配内存有更高的效率
- 栈上分配的内存不需要GC处理
- 堆上分配的内存使用完毕会交给GC处理
- 逃逸分析目的是决定内分配地址是栈还是堆
- 逃逸分析在编译阶段完成