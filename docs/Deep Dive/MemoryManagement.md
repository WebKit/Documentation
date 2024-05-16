# Memory Management

A deep dive into the memory management system utilized by WebKit.

## Overview

In WebKit, when an object is owned by another object,
we typically use [`std::unique_ptr`](https://en.cppreference.com/w/cpp/memory/unique_ptr) to express that ownership.
WebKit uses two primary management strategies when objects in other cases:
[garbage collection](https://en.wikipedia.org/wiki/Garbage_collection_(computer_science)) and [reference counting](https://en.wikipedia.org/wiki/Reference_counting).

## Reference counting in WebKit

### Overview

Most of WebCore objects are not managed by JavaScriptCore’s garbage collector.
Instead, we use [reference counting](https://en.wikipedia.org/wiki/Reference_counting).
We have two referencing counting pointer types:
[`RefPtr`](https://github.com/WebKit/WebKit/blob/main/Source/WTF/wtf/RefPtr.h)
and [`Ref`](https://github.com/WebKit/WebKit/blob/main/Source/WTF/wtf/Ref.h).
RefPtr is intended to behave like a C++ pointer whereas Ref is intended to behave like a C++ reference,
meaning that the former can be set to `nullptr` but the latter cannot.

```cpp
Ref<A> a1; // This will result in compilation error.
RefPtr<A> a2; // This is okay.
Ref<A> a3 = A::create(); // This is okay.
a3->f(); // Calls f() on an instance of A.
A* a4 = a3.ptr();
a4 = a2.get();
```

Unlike C++‘s[`std::shared_ptr`](https://en.cppreference.com/w/cpp/memory/shared_ptr),
the implementation of referencing counting is a part of a managed object.
The requirements for an object to be used with `RefPtr` and `Ref` is as follows:

* It implements `ref()` and `deref()` member functions
* Each call to `ref()` and `deref()` will increment and decrement its internal reference counter
* The initial call to `ref()` is implicit in `new`,
    after the object had been allocated and the constructor has been called upon;
    i.e. meaning that the reference count starts at 1.
* When `deref()` is called when its internal reference counter reaches 0, “this” object is destructed and deleted.

There is a convenience super template class,
[`RefCounted<T>`](https://github.com/WebKit/WebKit/blob/main/Source/WTF/wtf/RefCounted.h),
which implements this behavior for any inherited class T automatically.

### How to use RefPtr and Ref

When an object which implements the semantics required by RefPtr and Ref is created via new,
we must immediately *adopt* it into `Ref` type using `adoptRef` as follows:

```cpp
class A : public RefCounted<A> {
public:
    int m_foo;

    int f() { return m_foo; }

    static Ref<A> create() { return adoptRef(*new A); }
private:
    A() = default;
};
```

This will create an instance of `Ref` without calling `ref()` on the newly created object, avoiding the unnecessary increment from 0 to 1.
WebKit’s coding convention is to make the constructor private and add a static `create` function
which returns an instance of a ref counted object after adopting it. 

Note that returning RefPtr or Ref is efficient thanks to [copy elision](https://en.cppreference.com/w/cpp/language/copy_elision) in C++11,
and the following example does not create a temporary Ref object using copy constructor):

```cpp
Ref<A> a = A::create();
```

When passing the ownership of a ref-counted object to a function,
use rvalue reference with `WTFMove` (equivalent to `std::move` with some safety checks),
and use a regular reference when there is a guarantee for the caller to keep the object alive as follows:

```cpp
class B {
public:
    void setA(Ref<A>&& a) { m_a = WTFMove(a); }
private:
    Ref<A> m_a;
};

...

void createA(B& b) {
    b.setA(A::create());
}
```

Note that there is no `WTFMove` on `A::create` due to copy elision.

### Forwarding ref and deref

As mentioned above, objects that are managed with `RefPtr` and `Ref` do not necessarily have to inherit from `RefCounted`.
One common alternative is to forward `ref` and `deref` calls to another object which has the ownership.
For example, in the following example, `Parent` class owns `Child` class.
When someone stores `Child` in `Ref` or `RefPtr`, the referencing counting of `Parent` is incremented and decremented on behalf of `Child`.
Both `Parent` and `Child` are destructed when the last `Ref` or `RefPtr` to either object goes away.

```cpp
class Parent : RefCounted<Parent> {
public:
    static Ref<Parent> create() { return adoptRef(*new Parent); }

    Child& child() {
        if (!m_child)
            m_child = makeUnique<Child>(*this);
        return m_child
    }

private:
    std::unique_ptr<Child> m_child;    
};

class Child {
public:
    ref() { m_parent.ref(); }
    deref() { m_parent.deref(); }

private:
    Child(Parent& parent) : m_parent(parent) { }
    friend class Parent;

    Parent& m_parent;
}
```

### Reference Cycles

A reference cycle occurs when an object X which holds `Ref` or `RefPtr` to another object Y which in turns owns X by `Ref` or `RefPtr`.
For example, the following code causes a trivial memory leak because A holds a `Ref` of B, and B in turn holds `Ref` of the A:

```cpp
class A : RefCounted<A> {
public:
    static Ref<A> create() { return adoptRef(*new A); }
    B& b() {
        if (!m_b)
            m_b = B::create(*this);
        return m_b.get();
    }
private:
    Ref<B> m_b;
};

class B : RefCounted<B> {
public:
    static Ref<B> create(A& a) { return adoptRef(*new B(a)); }

private:
    B(A& a) : m_a(a) { }
    Ref<A> m_a;
};
```

We need to be particularly careful in WebCore with regards to garbage collected objects
because they often keep other ref counted C++ objects alive without having any `Ref` or `RefPtr` in C++ code.
It’s almost always incorrect to strongly keep JS value alive in WebCore code because of this.

### ProtectedThis Pattern

Because many objects in WebCore are managed by tree data structures,
a function that operates on a node of such a tree data structure can end up deleting itself (`this` object).
This is highly undesirable as such code often ends up having a use-after-free bug.

To prevent these kinds of bugs, we often employ a strategy of adding `protectedThis` local variable of `Ref` or `RefPtr` type, and store `this` object as [follows](https://github.com/WebKit/WebKit/blob/ea1a56ee11a26f292f3d2baed2a3aea95fea40f1/Source/WebCore/dom/ContainerNode.cpp#L632):

```cpp
ExceptionOr<void> ContainerNode::removeChild(Node& oldChild)
{
    // Check that this node is not "floating".
    // If it is, it can be deleted as a side effect of sending mutation events.
    ASSERT(refCount() || parentOrShadowHostNode());

    Ref<ContainerNode> protectedThis(*this);

    // NotFoundError: Raised if oldChild is not a child of this node.
    if (oldChild.parentNode() != this)
        return Exception { NotFoundError };

    if (!removeNodeWithScriptAssertion(oldChild, ChildChange::Source::API))
        return Exception { NotFoundError };

    rebuildSVGExtensionsElementsIfNecessary();
    dispatchSubtreeModifiedEvent();

    return { };
}
```

In this code, the act of removing `oldChild` can execute arbitrary JavaScript and delete `this` object.
As a result, `rebuildSVGExtensionsElementsIfNecessary` or `dispatchSubtreeModifiedEvent` might be called
after `this` object had already been free’ed if we didn’t have `protectedThis`,
which guarantees that this object’s reference count is at least 1
(because [Ref’s constructor](https://github.com/WebKit/WebKit/blob/ea1a56ee11a26f292f3d2baed2a3aea95fea40f1/Source/WTF/wtf/Ref.h#L64) increments the reference count by 1).

This pattern can be used for other objects that need to be *protected* from destruction inside a code block.
In the [following code](https://github.com/WebKit/WebKit/blob/ea1a56ee11a26f292f3d2baed2a3aea95fea40f1/Source/WebCore/dom/ContainerNode.cpp#L162),
`childToRemove` was passed in using C++ reference.
Because this function is going to remove this child node from `this` container node,
it can get destructed while the function is still running.
To prevent from having any chance of use-after-free bugs,
this function stores it in Ref (`protectedChildToRemove`) which guarantees the object to be alive until the function returns control back to the caller:

```cpp
ALWAYS_INLINE bool ContainerNode::removeNodeWithScriptAssertion(Node& childToRemove, ChildChangeSource source)
{
    Ref<Node> protectedChildToRemove(childToRemove);
    ASSERT_WITH_SECURITY_IMPLICATION(childToRemove.parentNode() == this);
    {
        ScriptDisallowedScope::InMainThread scriptDisallowedScope;
        ChildListMutationScope(*this).willRemoveChild(childToRemove);
    }
    ..
```

Also see [Darin’s RefPtr Basics](https://webkit.org/blog/5381/refptr-basics/) for further reading.

## Weak Pointers in WebKit

In some cases, it’s desirable to express a relationship between two objects without necessarily tying their lifetime.
In those cases, `WeakPtr` is useful. Like [std::weak_ptr](https://en.cppreference.com/w/cpp/memory/weak_ptr),
this class creates a non-owning reference to an object. There is a lot of legacy code which uses a raw pointer for this purpose,
but there is an ongoing effort to always use WeakPtr instead so do that in new code you’re writing.

To create a `WeakPtr` to an object, we need to make its class inherit from `CanMakeWeakPtr` as follows:

```cpp
class A : CanMakeWeakPtr<A> { }

...

function foo(A& a) {
    WeakPtr<A> weakA = a;
}
```

Dereferencing a `WeakPtr` will return `nullptr` when the referenced object is deleted.
Because creating a `WeakPtr` allocates an extra `WeakPtrImpl` object,
you’re still responsible to dispose of `WeakPtr` at appropriate time.

### WeakHashSet

While ordinary `HashSet` does not support having `WeakPtr` as its elements,
there is a specialized `WeakHashSet` class, which supports referencing a set of elements weakly.
Because `WeakHashSet` does not get notified when the referenced object is deleted,
the users / owners of `WeakHashSet` are still responsible for deleting the relevant entries from the set.
Otherwise, WeakHashSet will hold onto `WeakPtrImpl` until `computeSize` is called or rehashing happens.

### WeakHashMap

Like `WeakHashSet`, `WeakHashMap` is a specialized class to map a WeakPtr key with a value.
Because `WeakHashMap` does not get notified when the referenced object is deleted,
the users / owners of `WeakHashMap` are still responsible for deleting the relevant entries from the map.
Otherwise, the memory space used by `WeakPtrImpl` and its value will not be free'ed up until
next rehash or amortized cleanup cycle arrives (based on the total number of read or write operations).

## Reference Counting of DOM Nodes

[`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h) is a reference counted object but with a twist.
It has a [separate boolean flag](https://github.com/WebKit/WebKit/blob/297c01a143f649b34544f0cb7a555decf6ecbbfd/Source/WebCore/dom/Node.h#L832)
indicating whether it has a [parent](https://dom.spec.whatwg.org/#concept-tree-parent) node or not.
A `Node` object is [not deleted](https://github.com/WebKit/WebKit/blob/297c01a143f649b34544f0cb7a555decf6ecbbfd/Source/WebCore/dom/Node.h#L801)
so long as it has a reference count above 0 or this boolean flag is set.
The boolean flag effectively functions as a `RefPtr` from a parent `Node`
to each one of its [child](https://dom.spec.whatwg.org/#concept-tree-child) `Node`.
We do this because `Node` only knows its [first child](https://dom.spec.whatwg.org/#concept-tree-first-child)
and its [last child](https://dom.spec.whatwg.org/#concept-tree-last-child)
and each [sibling](https://dom.spec.whatwg.org/#concept-tree-sibling) nodes are implemented
as a [doubly linked list](https://en.wikipedia.org/wiki/Doubly_linked_list) to allow
efficient [insertion](https://dom.spec.whatwg.org/#concept-node-insert)
and [removal](https://dom.spec.whatwg.org/#concept-node-remove) and traversal of sibling nodes.

Conceptually, each `Node` is kept alive by its root node and external references to it,
and we use the root node as an opaque root of each `Node`'s JS wrapper.
Therefore the JS wrapper of each `Node` is kept alive as long as either the node itself
or any other node which shares the same root node is visited by the garbage collector.

On the other hand, a `Node` does not keep its parent or any of its
[shadow-including ancestor](https://dom.spec.whatwg.org/#concept-shadow-including-ancestor) `Node` alive
either by reference counting or via the boolean flag even though the JavaScript API requires this to be the case.
In order to implement this DOM API behavior,
WebKit [will create](https://github.com/WebKit/WebKit/blob/297c01a143f649b34544f0cb7a555decf6ecbbfd/Source/WebCore/bindings/js/JSNodeCustom.cpp#L174)
a JS wrapper for each `Node` which is being removed from its parent if there isn't already one.
A `Node` which is a root node (of the newly removed [subtree](https://dom.spec.whatwg.org/#concept-tree)) is an opaque root of its JS wrapper,
and the garbage collector will visit this opaque root if there is any JS wrapper in the removed subtree that needs to be kept alive.
In effect, this keeps the new root node and all its [descendant](https://dom.spec.whatwg.org/#concept-tree-descendant) nodes alive
if the newly removed subtree contains any node with a live JS wrapper, preserving the API contract.

It's important to recognize that storing a `Ref` or a `RefPtr` to another `Node` in a `Node` subclass
or an object directly owned by the Node can create a [reference cycle](https://en.wikipedia.org/wiki/Reference_counting#Dealing_with_reference_cycles),
or a reference that never gets cleared.
It's not guaranteed that every node is [disconnected](https://dom.spec.whatwg.org/#connected)
from a [`Document`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Document.h) at some point in the future,
and some `Node` may always have a parent node or a child node so long as it exists.
Only permissible circumstances in which a `Ref` or a `RefPtr` to another `Node` can be stored
in a `Node` subclass or other data structures owned by it is if it's temporally limited.
For example, it's okay to store a `Ref` or a `RefPtr` in
an enqueued [event loop task](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/EventLoop.h#L69).
In all other circumstances, `WeakPtr` should be used to reference another `Node`,
and JS wrapper relationships such as opaque roots should be used to preserve the lifecycle ties between `Node` objects.

It's equally crucial to observe that keeping C++ Node object alive by storing `Ref` or `RefPtr`
in an enqueued [event loop task](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/EventLoop.h#L69)
does not keep its JS wrapper alive, and can result in the JS wrapper of a conceptually live object to be erroneously garbage collected.
To avoid this problem, use [`GCReachableRef`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/GCReachableRef.h) instead
to temporarily hold a strong reference to a node over a period of time.
For example, [`HTMLTextFormControlElement::scheduleSelectEvent()`](https://github.com/WebKit/WebKit/blob/297c01a143f649b34544f0cb7a555decf6ecbbfd/Source/WebCore/html/HTMLTextFormControlElement.cpp#L547)
uses `GCReachableRef` to fire an event in an event loop task:
```cpp
void HTMLTextFormControlElement::scheduleSelectEvent()
{
    document().eventLoop().queueTask(TaskSource::UserInteraction, [protectedThis = GCReachableRef { *this }] {
        protectedThis->dispatchEvent(Event::create(eventNames().selectEvent, Event::CanBubble::Yes, Event::IsCancelable::No));
    });
}
```

Alternatively, we can make it inherit from an [active DOM object](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/ActiveDOMObject.h),
and use one of the following functions to enqueue a task or an event:

 - [`queueTaskKeepingObjectAlive`](https://github.com/WebKit/WebKit/blob/297c01a143f649b34544f0cb7a555decf6ecbbfd/Source/WebCore/dom/ActiveDOMObject.h#L107)
 - [`queueCancellableTaskKeepingObjectAlive`](https://github.com/WebKit/WebKit/blob/297c01a143f649b34544f0cb7a555decf6ecbbfd/Source/WebCore/dom/ActiveDOMObject.h#L115)
 - [`queueTaskToDispatchEvent`](https://github.com/WebKit/WebKit/blob/297c01a143f649b34544f0cb7a555decf6ecbbfd/Source/WebCore/dom/ActiveDOMObject.h#L124)
 - [`queueCancellableTaskToDispatchEvent`](https://github.com/WebKit/WebKit/blob/297c01a143f649b34544f0cb7a555decf6ecbbfd/Source/WebCore/dom/ActiveDOMObject.h#L130)

[`Document`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Document.h) node has one more special quirk
because every [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h) can have access to a document
via [`ownerDocument` property](https://developer.mozilla.org/en-US/docs/Web/API/Node/ownerDocument)
whether Node is [connected](https://dom.spec.whatwg.org/#connected) to the document or not.
Every document has a regular reference count used by external clients and
[referencing node count](https://github.com/WebKit/WebKit/blob/297c01a143f649b34544f0cb7a555decf6ecbbfd/Source/WebCore/dom/Document.h#L2093).
The referencing node count of a document is the total number of nodes whose `ownerDocument` is the document.
A document is [kept alive](https://github.com/WebKit/WebKit/blob/297c01a143f649b34544f0cb7a555decf6ecbbfd/Source/WebCore/dom/Document.cpp#L749)
so long as its reference count and node referencing count is above 0.
In addition, when the regular reference count is to become 0,
it clears various states including its internal references to owning Nodes to sever any reference cycles with them.
A document is special in that sense that it can store `RefPtr` to other nodes.
Note that whilst the referencing node count acts like `Ref` from each `Node` to its owner `Document`,
storing a `Ref` or a `RefPtr` to the same document or any other document will create
a [reference cycle](https://en.wikipedia.org/wiki/Reference_counting#Dealing_with_reference_cycles)
and should be avoided unless it's temporally limited as noted above.
