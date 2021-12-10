---
title: Java容器学习笔记
---
# Java容器学习笔记

### ArrayList与LinkList对比：

- 性能：《Java编程思想》指出，ArrayList插入移除元素较慢，ArrayList添加元素的速度比LinkList快。。LinkList插入移除元素速度优于ArrayList，且在数据量大时，ArrayList移除元素异常缓慢（按照元素顺序插入移除，若倒序插入移除则快于LinkList），其中的原因是LinkList使用双向链表存储数据，移除时只需要修改待移除元素的前后节点的next与prev位置即可，而ArrayList则涉及到数组的拷贝，倒序的情况下，ArrayList只需要将末尾元素移除即可。
- 建议：在涉及元素删除的List中，建议使用LinkList，其他情况可使用ArrayList。ArrayList使用在查询比较多，但是插入和删除比较少的情况，而LinkedList用在查询比较少而插入删除比较多的情况。

### ArrayList、LinkList、Vector、Stack中只有Stack、Vector是线程安全的类，线程安全的List还有CopyOnWriteArrayList和Collections.synchronizedList()。Collections.synchronizedList()使用装饰模式为传入的List操作加上同步锁。

### Stack底层数据结构是Vector，Vector的所有操作都加了synchronized关键字，Vector的底层使用数组保存数据，类似与ArrayList。一般多线程状态下使用List会选择Vector。

### HashSet底层数据结构是HashMap

### LinkedHashSet底层数据结构是LinkedHashMap
