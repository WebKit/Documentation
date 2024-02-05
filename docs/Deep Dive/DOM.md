# DOM

A deep dive into the Document Object Model.

## Introduction

[Document Object Model](https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model)
(often abbreviated as DOM) is the tree data structured resulted from parsing HTML.
It consists of one or more instances of subclasses of [Node](https://developer.mozilla.org/en-US/docs/Web/API/Node)
and represents the document tree structure. Parsing a simple HTML like this:

```cpp
<!DOCTYPE html>
<html>
<body>hi</body>
</html>
```

Will generate the following six distinct DOM nodes:

* [Document](https://developer.mozilla.org/en-US/docs/Web/API/Document)
    * [DocumentType](https://developer.mozilla.org/en-US/docs/Web/API/DocumentType)
    * [HTMLHtmlElement](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/html)
        * [HTMLHeadElement](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/head)
        * [HTMLBodyElement](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/body)
            * [Text](https://developer.mozilla.org/en-US/docs/Web/API/Text) with the value of “hi”

Note that HTMLHeadElement (i.e. `<head>`) is created implicitly by WebKit
per the way [HTML parser](https://html.spec.whatwg.org/multipage/parsing.html#parsing) is specified.

Broadly speaking, DOM node divides into the following categories:

* [Container nodes](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/ContainerNode.h) such as [Document](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Document.h), [Element](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Element.h), and [DocumentFragment](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/DocumentFragment.h).
* Leaf nodes such as [DocumentType](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/DocumentType.h), [Text](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Text.h), and [Attr](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Attr.h).

[Document](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Document.h) node,
as the name suggests a single HTML, SVG, MathML, or other XML document,
and is the [owner](https://github.com/WebKit/WebKit/blob/ea1a56ee11a26f292f3d2baed2a3aea95fea40f1/Source/WebCore/dom/Node.h#L359) of every node in the document.
It is the very first node in any document that gets created and the very last node to be destroyed.

Note that a single web [page](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/page/Page.h) may consist of multiple documents
since [iframe](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe)
and [object](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/object) elements may contain
a child [frame](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/page/Frame.h),
and form a [frame tree](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/page/FrameTree.h).
Because JavaScript can [open a new window](https://developer.mozilla.org/en-US/docs/Web/API/Window/open)
under user gestures and have [access back to its opener](https://developer.mozilla.org/en-US/docs/Web/API/Window/opener),
multiple web pages across multiple tabs might be able to communicate with one another via JavaScript API
such as [postMessage](https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage).

## Node’s Type and State flags

Each node has a set of [`TypeFlag`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/Node.h#L596),
which are set at construction time and immutable, and a set of [`StateFlag`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/Node.h#L617),
which can be set or unset throughout [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)’s lifetime.
Node also makes use of [`EventTargetFlag`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/EventTarget.h#L188)
for indicating ownership and relationship with other objects.
For example, [`TypeFlag::IsElement`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/Node.h#L600C9-L600C18)
is set whenever a [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)
is a subclass of [`Element`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Element.h).
[`StateFlag::IsParsingChildren`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/Node.h#L620C9-L620C26)
is set whenever a [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)
is in the state of its child nodes being [parsed](https://html.spec.whatwg.org/multipage/parsing.html).
[`EventTargetFlag::IsConnected`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/EventTarget.h#L193)
is set whenever a [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h) is [connected](https://dom.spec.whatwg.org/#connected).
These flags are updated by each subclass of [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h) throughout its lifetime.
Note that these flags are set or unset within a specific function.
For example, [`EventTargetFlag::IsConnected`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/EventTarget.h#L193)
is set in [`Node::insertedIntoAncestor`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/Node.cpp#L1474).
It means that any code which runs prior to [`Node::insertedIntoAncestor`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/Node.cpp#L1474)
running on a given `Node` will observe an outdated value of
[`EventTargetFlag::IsConnected`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/EventTarget.h#L193).

## Insertion and Removal of DOM Nodes

In order to construct a [DOM](https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model) tree,
we create a DOM [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)
and [insert](https://github.com/WebKit/WebKit/blob/0a9ebe9a13e511c2848b7ed3dfd887be266d42bb/Source/WebCore/dom/ContainerNode.cpp#L279)
it into a [`ContainerNode`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/ContainerNode.h)
such as [`Document`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Document.h)
and [`Element`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Element.cpp).
An insertion of a node starts with a [validation](https://github.com/WebKit/WebKit/blob/0a9ebe9a13e511c2848b7ed3dfd887be266d42bb/Source/WebCore/dom/ContainerNode.cpp#L477),
then [removal of the node from its old parent](https://github.com/WebKit/WebKit/blob/0a9ebe9a13e511c2848b7ed3dfd887be266d42bb/Source/WebCore/dom/ContainerNode.cpp#L329)
if there is any. Either of these two steps can synchronously execute JavaScript via [mutation events](https://developer.mozilla.org/en-US/docs/Web/API/MutationEvent)
and therefore can synchronously mutate tree’s state.
Because of that, we need to [check the validity again](https://github.com/WebKit/WebKit/blob/0a9ebe9a13e511c2848b7ed3dfd887be266d42bb/Source/WebCore/dom/ContainerNode.cpp#L866)
before proceeding with the insertion.

An actual insertion of a DOM [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)
is implemented using [`executeNodeInsertionWithScriptAssertion`](https://github.com/WebKit/WebKit/blob/0a9ebe9a13e511c2848b7ed3dfd887be266d42bb/Source/WebCore/dom/ContainerNode.cpp#L279)
or [`executeParserNodeInsertionIntoIsolatedTreeWithoutNotifyingParent`](https://github.com/WebKit/WebKit/blob/0a9ebe9a13e511c2848b7ed3dfd887be266d42bb/Source/WebCore/dom/ContainerNode.cpp#L310).
To start off, these functions instantiate a [RAII](https://en.wikipedia.org/wiki/Resource_acquisition_is_initialization)-style
object [`ScriptDisallowedScope`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/ScriptDisallowedScope.h),
which forbids JavaScript execution during its lifetime, do the insertion,
then [notify the child and its descendant](https://github.com/WebKit/WebKit/blob/b7bd89ba227d492f2eeefca628afea8480f556d9/Source/WebCore/dom/ContainerNodeAlgorithms.cpp#L97)
with [`insertedIntoAncestor`](https://github.com/WebKit/WebKit/blob/b7bd89ba227d492f2eeefca628afea8480f556d9/Source/WebCore/dom/Node.h#L474).
Note that [`insertedIntoAncestor`](https://github.com/WebKit/WebKit/blob/b7bd89ba227d492f2eeefca628afea8480f556d9/Source/WebCore/dom/Node.h#L474)
can be called when a given [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)
[becomes connected](https://html.spec.whatwg.org/multipage/infrastructure.html#becomes-connected)
to a [`Document`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Document.h), or it’s inserted into a disconnected subtree.
It’s not correct to assume that `this` [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)
is always [connected](https://dom.spec.whatwg.org/#connected) to a
[`Document`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Document.h) in `insertedIntoAncestor`.
To run code only when a [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)
[becomes connected](https://html.spec.whatwg.org/multipage/infrastructure.html#becomes-connected) to a document,
check [`InsertionType`](https://github.com/WebKit/WebKit/blob/b7bd89ba227d492f2eeefca628afea8480f556d9/Source/WebCore/dom/Node.h#L468)’s
[`connectedToDocument`](https://github.com/WebKit/WebKit/blob/b7bd89ba227d492f2eeefca628afea8480f556d9/Source/WebCore/dom/Node.h#L469) boolean.
It’s also not necessarily true that this [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)’s immediate parent node changed.
It could be this [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)’s ancestor that got inserted into a new parent.
To run code only when this [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)’s immediate parent had changed,
check if node’s parent node matches [`parentOfInsertedTree`](https://github.com/WebKit/WebKit/blob/b7bd89ba227d492f2eeefca628afea8480f556d9/Source/WebCore/dom/Node.h#L474).
There are cases in which code must run whenever its [`TreeScope`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/TreeScope.h)
([`ShadowRoot`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/ShadowRoot.h)
or [`Document`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Document.h)) had changed.
In this case, check [`InsertionType`](https://github.com/WebKit/WebKit/blob/b7bd89ba227d492f2eeefca628afea8480f556d9/Source/WebCore/dom/Node.h#L468)’s
[`treeScopeChanged`](https://github.com/WebKit/WebKit/blob/b7bd89ba227d492f2eeefca628afea8480f556d9/Source/WebCore/dom/Node.h#L470) boolean.
In all cases, it’s vital that no code invoked by `insertedIntoAncestor` attempts to execute JavaScript synchronously, for example, by dispatching an event.
Doing so will result in a [release assert](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/bindings/js/ScriptController.cpp#L794) (i.e. crash).
If an element must dispatch events or otherwise execute arbitrary author JavaScript,
return [`NeedsPostInsertionCallback`](https://github.com/WebKit/WebKit/blob/b7bd89ba227d492f2eeefca628afea8480f556d9/Source/WebCore/dom/Node.h#L466) from `insertedIntoAncestor`.
This will result in a call to [`didFinishInsertingNode`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h#L475C18-L475C40)
which unlike `insertedIntoAncestor` allows script execution (it gets called only after
[`ScriptDisallowedScope`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/ScriptDisallowedScope.h) has been out of scope).
But note that the tree’s state may have been mutated by other scripts between when `insertedIntoAncestor` is called and by when `didFinishInsertingNode` is called
so it’s not safe to assume any tree state condition which was true during `insertedIntoAncestor` to be true in `didFinishInsertingNode`.
It’s also not safe to leave Node in an inconsistent state at the end of `insertedIntoAncestor`
because JavaScript may invoke any API on such a Node between `insertedIntoAncestor` and `didFinishInsertingNode`.
After invoking `insertedIntoAncestor`, these functions invoke
[`childrenChanged`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/ContainerNode.h#L111) on the new parent.
This function has the first opportunity to execute any JavaScript in response to a child node being inserted.
[`HTMLScriptElement`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/html/HTMLScriptElement.h),
for example, may execute its script in [its `childrenChanged`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/ScriptElement.cpp#L92).
Finally, the functions will invoke [`didFinishInsertingNode`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/Node.h#L475)
on [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)s which returned
[`NeedsPostInsertionCallback`](https://github.com/WebKit/WebKit/blob/b7bd89ba227d492f2eeefca628afea8480f556d9/Source/WebCore/dom/Node.h#L466)
from its `insertedIntoAncestor` and [trigger mutation events](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/ContainerNode.cpp#L1056)
such as `DOMNodeInsertedEvent`.

The removal of a DOM [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h) from its parent is implemented using
[`ContainerNode::removeAllChildrenWithScriptAssertion`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/ContainerNode.cpp#L89)
and [`ContainerNode::removeChildWithScriptAssertion`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/ContainerNode.cpp#L180).
These functions first [dispatch mutation events](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/ContainerNode.cpp#L1076)
and check if child’s parent is still the same container node.
If it’s not, we stop and exit early. Next, they [disconnect any subframes](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/ContainerNodeAlgorithms.cpp#L263)
in the subtree to be removed. These functions then instantiate a [RAII](https://en.wikipedia.org/wiki/Resource_acquisition_is_initialization)-style object
[`ScriptDisallowedScope`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/ScriptDisallowedScope.h),
which forbids JavaScript execution during its lifetime like the insertion counterparts,
and [notify](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/Document.cpp#L5828)
[`Document`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Document.h) of the node’s removal so that objects such as
[`NodeIterator`](https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator) and [`Range`](https://developer.mozilla.org/en-US/docs/Web/API/Range) can be updated.
The functions will then do the removal and notify the child and its descendant with
[`removedFromAncestor`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/ContainerNodeAlgorithms.cpp#L177).
Note that [`removedFromAncestor`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/ContainerNodeAlgorithms.cpp#L177)
can be called when a given [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)
[becomes disconnected](https://html.spec.whatwg.org/multipage/infrastructure.html#becomes-disconnected)
from a [`Document`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Document.h), or it’s removed from an already disconnected subtree.
It’s not correct to assume that `this` [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)
used to be [connected](https://dom.spec.whatwg.org/#connected) to a [`Document`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Document.h) in `removedFromAncestor`.
To run code only when a [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)
[becomes disconnected](https://html.spec.whatwg.org/multipage/infrastructure.html#becomes-disconnected) from a document,
check [`RemovalType`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/Node.h#L477)’s
[`disconnectedFromDocument`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/Node.h#L478) boolean.
It’s also not necessarily true that this [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)’s immediate parent node changed.
It could be this [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)’s ancestor that got removed from its old parent.
To run code only when this [`Node`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Node.h)’s immediate parent had changed,
check if node’s parent node is `nullptr`.
To run code whenever its [`TreeScope`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/TreeScope.h)
([`ShadowRoot`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/ShadowRoot.h)
or [`Document`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Document.h)) had changed,
check [`RemovalType`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/Node.h#L477)’s
[`treeScopeChanged`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/Node.h#L479C14-L479C30) boolean.
In all cases, it’s vital that no code invoked by
[`removedFromAncestor`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/ContainerNodeAlgorithms.cpp#L177)
attempts to execute JavaScript synchronously, for example, by dispatching an event.
Doing so will result in a [release assert](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/bindings/js/ScriptController.cpp#L794) (i.e. crash).
If an element must dispatch events or otherwise execute arbitrary author JavaScript,
[queue a task](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/EventLoop.h#L206) to do so.
After invoking `removedFromAncestor`, these functions invoke
[`childrenChanged`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/ContainerNode.h#L111) on the old parent.

Additionally, certain [`StateFlag`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/Node.h#L617) and
[`EventTargetFlag`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/EventTarget.h#L188)
might be outdated in `insertedIntoAncestor` and `removedFromAncestor`.
For example, [`EventTargetFlag::IsConnected`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/EventTarget.h#L193)
flag is not set or unset until [`Node::insertedIntoAncestor`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/Node.cpp#L1474)
or [`Node::removedFromAncestor`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/Node.cpp#L1486) is called.
Accessing other node’s states and member functions are even trickier.
Because `insertedIntoAncestor` or `removedFromAncestor` may not have been called on such nodes,
functions like [`getElementById`](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/TreeScope.h#L83)
and [`rootNode`](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/dom/ContainerNode.h#L209)
will return wrong results for those nodes.
Code which runs inside these functions must carefully [avoid these pitfalls](https://github.com/WebKit/WebKit/blob/5ee1e908b6ed778eca6b6a72997648b10d4bcbf4/Source/WebCore/html/FormAssociatedElement.cpp#L62).
