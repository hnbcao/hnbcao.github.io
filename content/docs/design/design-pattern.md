---
title: 设计模式简介
weight: 21
---

# 设计模式简介

## 一、设计模式原则

- **开闭原则**：开闭原则（Open Closed Principle，OCP）由勃兰特·梅耶（Bertrand Meyer）提出，他在 1988 年的著作《面向对象软件构造》（Object Oriented Software Construction）中提出：**软件实体应当对扩展开放，对修改关闭（Software entities should be open for extension，but closed for modification）**，这就是开闭原则的经典定义。

- **里氏替换原则**：里氏替换原则（Liskov Substitution Principle，LSP）由麻省理工学院计算机科学实验室的里斯科夫（Liskov）女士在 1987 年的“面向对象技术的高峰会议”（OOPSLA）上发表的一篇文章《数据抽象和层次》（Data Abstraction and Hierarchy）里提出来的，她提出：**继承必须确保超类所拥有的性质在子类中仍然成立（Inheritance should ensure that any property proved about supertype objects also holds for subtype objects）**。

- **依赖倒置原则**：依赖倒置原则（Dependence Inversion Principle，DIP）的原始定义为，**高层模块不应该依赖低层模块，两者都应该依赖其抽象；抽象不应该依赖细节，细节应该依赖抽象（High level modules shouldnot depend upon low level modules.Both should depend upon abstractions.Abstractions should not depend upon details. Details should depend upon abstractions）**。其核心思想是：**要面向接口编程，不要面向实现编程**。

- **单一职责原则**：单一职责原则（Single Responsibility Principle，SRP）又称单一功能原则，由罗伯特·C.马丁（Robert C. Martin）于《敏捷软件开发：原则、模式和实践》一书中提出的。这里的职责是指类变化的原因，单一职责原则规定**一个类应该有且仅有一个引起它变化的原因，否则类应该被拆分（There should never be more than one reason for a class to change）**。

- **接口隔离原则**：接口隔离原则（Interface Segregation Principle，ISP）要求程序员尽量将臃肿庞大的接口拆分成更小的和更具体的接口，让接口中只包含客户感兴趣的方法。

- **迪米特法则**：迪米特法则（Law of Demeter，LoD）又叫作最少知识原则（Least Knowledge Principle，LKP)，迪米特法则的定义是：只与你的直接朋友交谈，不跟“陌生人”说话（Talk only to your immediate friends and not to strangers）。其含义是：**如果两个软件实体无须直接通信，那么就不应当发生直接的相互调用，可以通过第三方转发该调用**。其目的是降低类之间的耦合度，提高模块的相对独立性。

- **合成复用原则**：合成复用原则（Composite Reuse Principle，CRP）又叫组合/聚合复用原则（Composition/Aggregate Reuse Principle，CARP）。它要求在软件复用时，要**尽量先使用组合或者聚合等关联关系来实现，其次才考虑使用继承关系来实现**。

## 二、设计模式分类

1. 根据目的来分

    根据模式是用来完成什么工作来划分，这种方式可分为创建型模式、结构型模式和行为型模式 3 种。

    - 创建型模式：用于描述“怎样创建对象”，它的主要特点是“将对象的创建与使用分离”。GoF 中提供了单例、原型、工厂方法、抽象工厂、建造者等 5 种创建型模式。

    - 结构型模式：用于描述如何将类或对象按某种布局组成更大的结构，GoF 中提供了代理、适配器、桥接、装饰、外观、享元、组合等 7 种结构型模式。

    - 行为型模式：用于描述类或对象之间怎样相互协作共同完成单个对象都无法单独完成的任务，以及怎样分配职责。GoF 中提供了模板方法、策略、命令、职责链、状态、观察者、中介者、迭代器、访问者、备忘录、解释器等 11 种行为型模式。

2. 根据作用范围来分

    根据模式是主要用于类上还是主要用于对象上来分，这种方式可分为类模式和对象模式两种。

    - 类模式：用于处理类与子类之间的关系，这些关系通过继承来建立，是静态的，在编译时刻便确定下来了。GoF中的工厂方法、（类）适配器、模板方法、解释器属于该模式。

    - 对象模式：用于处理对象之间的关系，这些关系可以通过组合或聚合来实现，在运行时刻是可以变化的，更具动态性。GoF 中除了以上 4 种，其他的都是对象模式。

    表 1 介绍了这 23 种设计模式的分类。

    | 范围\目的 | 创建型模式 | 结构型模式 | 行为型模式 |
    | :-: | - | - | - |
    | 类模式 | 工厂方法	(类） | 适配器 | 模板方法、解释器 |
    | 对象模式 | 单例</br>原型</br>抽象工厂</br>建造者 | 代理</br>(对象）适配器</br>桥接</br>装饰</br>外观</br>享元</br>组合	| 策略</br>命令</br>职责链</br>状态</br>观察者</br>中介者</br>迭代器</br>访问者</br>备忘录 |

3. GoF的23种设计模式的功能

    前面说明了 GoF 的 23 种设计模式的分类，现在对各个模式的功能进行介绍。

    **创建型模式(Creational)**：

    - 单例（Singleton）模式：某个类只能生成一个实例，该类提供了一个全局访问点供外部获取该实例，其拓展是有限多例模式。
- 原型（Prototype）模式：将一个对象作为原型，通过对其进行复制而克隆出多个和原型类似的新实例。
    - 工厂方法（Factory Method）模式：定义一个用于创建产品的接口，由子类决定生产什么产品。
- 抽象工厂（AbstractFactory）模式：提供一个创建产品族的接口，其每个子类可以生产一系列相关的产品。
    - 建造者（Builder）模式：将一个复杂对象分解成多个相对简单的部分，然后根据不同需要分别创建它们，最后构建成该复杂对象。

    **结构型模式(Structural)**：

    - 代理（Proxy）模式：为某对象提供一种代理以控制对该对象的访问。即客户端通过代理间接地访问该对象，从而限制、增强或修改该对象的一些特性。
- 适配器（Adapter）模式：将一个类的接口转换成客户希望的另外一个接口，使得原本由于接口不兼容而不能一起工作的那些类能一起工作。
    - 桥接（Bridge）模式：将抽象与实现分离，使它们可以独立变化。它是用组合关系代替继承关系来实现，从而降低了抽象和实现这两个可变维度的耦合度。
- 装饰（Decorator）模式：动态的给对象增加一些职责，即增加其额外的功能。
    - 外观（Facade）模式：为多个复杂的子系统提供一个一致的接口，使这些子系统更加容易被访问。
- 享元（Flyweight）模式：运用共享技术来有效地支持大量细粒度对象的复用。**数据库连接池**
    - 组合（Composite）模式：将对象组合成树状层次结构，使用户对单个对象和组合对象具有一致的访问性。

    **行为型模式(Behavioral)**：

    - 模板方法（TemplateMethod）模式：定义一个操作中的算法骨架，而将算法的一些步骤延迟到子类中，使得子类可以不改变该算法结构的情况下重定义该算法的某些特定步骤。

    - 策略（Strategy）模式：定义了一系列算法，并将每个算法封装起来，使它们可以相互替换，且算法的改变不会影响使用算法的客户。
- 命令（Command）模式：将一个请求封装为一个对象，使发出请求的责任和执行请求的责任分割开。
    - 职责链（Chain of Responsibility）模式：把请求从链中的一个对象传到下一个对象，直到请求被响应为止。通过这种方式去除对象之间的耦合。
- 状态（State）模式：允许一个对象在其内部状态发生改变时改变其行为能力。
    - 观察者（Observer）模式：多个对象间存在一对多关系，当一个对象发生改变时，把这种改变通知给其他多个对象，从而影响其他对象的行为。
- 中介者（Mediator）模式：定义一个中介对象来简化原有对象之间的交互关系，降低系统中对象间的耦合度，使原有对象之间不必相互了解。
    - 迭代器（Iterator）模式：提供一种方法来顺序访问聚合对象中的一系列数据，而不暴露聚合对象的内部表示。
- 访问者（Visitor）模式：在不改变集合元素的前提下，为一个集合中的每个元素提供多种访问方式，即每个元素有多个访问者对象访问。
    - 备忘录（Memento）模式：在不破坏封装性的前提下，获取并保存一个对象的内部状态，以便以后恢复它。
- 解释器（Interpreter）模式：提供如何定义语言的文法，以及对语言句子的解释方法，即解释器。

## 三、设计模式使用频次总结

- 创建型模式(Creational)

  高频： 工厂方法模式(Factory Method ) 、抽象工厂模式(Abstract Factory ) 、单例模式(Singleton)、建 造者模式(Builder)

  低频 ： 原型模式( Prototype )

- 结构型模式(Structural)

  高频： 代理模式(Proxy ) 、门面模式(Facade ) 、装饰器模式(Decorator) 、享元模式(Flyweight) 、适配器模式(Adapter)、组合模式(Composite )

  低频 ： 桥接模式( Bridge )

- 行为型模式(Behavioral)

  高频： 模板方法模式(Template Method ) 、策略模式(Strategy ) 、 责任链模式(Chain of Responsibility ) 、状态模式(State )

  低频： 备忘录模式(Memento ) 、 观察者模式(Observer) s 迭代器模式(Iterator) s 中介者模式(Mediator)、命令模式(Command ) 、解释器模式( Interpreter) 、访问者模式(Visitor)

## 四、模式对比

**创建型模式**：

- 工厂方法模式(Factory Method ) 
- 抽象工厂模式(Abstract Factory ) 
- 单例模式(Singleton)
- 建造者模式(Builder)

**结构型模式**：

- 代理模式(Proxy ) 
- 门面模式(Facade ) 
- 装饰器模式(Decorator) 
- 享元模式(Flyweight) 
- 适配器模式(Adapter)
- 组合模式(Composite )

**行为型模式**：

- 模板方法模式(Template Method ) 
- 策略模式(Strategy ) 
-  责任链模式(Chain of Responsibility ) 
- 状态模式(State )